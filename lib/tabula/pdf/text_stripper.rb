# frozen_string_literal: true

require "pdf-reader"

module Tabula
  # Extracts text elements from PDF pages using pdf-reader.
  # Uses pdf-reader's PageTextReceiver for proper font encoding and CMap handling.
  class TextStripper
    # @param page [PDF::Reader::Page] pdf-reader page object
    def initialize(page)
      @page = page
      @text_elements = []
      @min_char_width = Float::INFINITY
      @min_char_height = Float::INFINITY
    end

    # Extract text elements from the page
    # @return [Array<TextElement>] extracted text elements
    def extract
      # Use pdf-reader's PageTextReceiver for proper font encoding
      receiver = PDF::Reader::PageTextReceiver.new
      receiver.page = @page
      @page.walk(receiver)

      # Get character-level runs (not merged)
      runs = receiver.runs(
        merge: false,
        skip_zero_width: false,
        skip_overlapping: false
      )

      # Get page dimensions and rotation
      rotation = @page.attributes[:Rotate] || 0

      runs.each do |run|
        next if run.text.nil? || run.text.empty?
        next unless printable?(run.text)

        # pdf-reader already applies rotation transformation
        # For rotated pages, y coordinates are negative
        # For non-rotated pages, we need to flip from bottom-origin to top-origin
        if rotation == 90 || rotation == 270
          # Rotated pages: y is negative, convert to positive
          top = run.y.abs
        else
          # Non-rotated pages: convert from bottom-origin to top-origin
          page_height = calculate_page_height
          top = page_height - run.y
        end

        left = run.x
        width = run.width
        height = run.font_size

        # Detect text direction from Unicode character properties
        direction = rtl_text?(run.text) ? TextElement::DIRECTION_RTL : TextElement::DIRECTION_LTR

        element = TextElement.new(
          top: top,
          left: left,
          width: width,
          height: height,
          text: run.text,
          font_name: nil, # pdf-reader doesn't expose font name in runs
          font_size: run.font_size,
          width_of_space: estimate_space_width(run),
          direction: direction
        )

        @text_elements << element

        if width.positive?
          @min_char_width = [@min_char_width, width].min
        end
        if height.positive?
          @min_char_height = [@min_char_height, height].min
        end
      end

      @text_elements
    end

    attr_reader :min_char_width, :min_char_height

    private

    def calculate_page_height
      box = @page.attributes[:CropBox] || @page.attributes[:MediaBox]
      (box[3].to_f - box[1].to_f).abs
    end

    # Check if character is printable (port of Java's isPrintable)
    def printable?(text)
      return false if text.nil? || text.empty?

      text.each_char do |char|
        code = char.ord

        # Filter control characters except space, tab, newline
        return false if code < 0x20 && code != 0x09 && code != 0x0A && code != 0x0D

        # Filter delete character
        return false if code == 0x7F

        # Filter Unicode replacement character
        return false if code == 0xFFFD

        # Filter null character
        return false if code == 0x00
      end

      true
    end

    # Estimate width of space character based on font size
    def estimate_space_width(run)
      # Approximate space width as 0.25 of font size (common for proportional fonts)
      run.font_size * 0.25
    end

    # Detect if text contains RTL (right-to-left) characters
    # Uses Unicode ranges for Arabic, Hebrew, and other RTL scripts
    def rtl_text?(text)
      return false if text.nil? || text.empty?

      text.each_char do |char|
        code = char.ord

        # Arabic (0600-06FF, 0750-077F, 08A0-08FF, FB50-FDFF, FE70-FEFF)
        return true if code >= 0x0600 && code <= 0x06FF
        return true if code >= 0x0750 && code <= 0x077F
        return true if code >= 0x08A0 && code <= 0x08FF
        return true if code >= 0xFB50 && code <= 0xFDFF
        return true if code >= 0xFE70 && code <= 0xFEFF

        # Hebrew (0590-05FF, FB1D-FB4F)
        return true if code >= 0x0590 && code <= 0x05FF
        return true if code >= 0xFB1D && code <= 0xFB4F

        # Syriac (0700-074F)
        return true if code >= 0x0700 && code <= 0x074F

        # Thaana (0780-07BF)
        return true if code >= 0x0780 && code <= 0x07BF

        # N'Ko (07C0-07FF)
        return true if code >= 0x07C0 && code <= 0x07FF
      end

      false
    end
  end
end
