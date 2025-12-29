# frozen_string_literal: true

module Tabula
  # Represents a single text element (character or glyph) extracted from a PDF.
  # Contains position, dimensions, and font information.
  class TextElement < Rectangle
    # Text direction constants
    DIRECTION_LTR = 0
    DIRECTION_RTL = 1

    attr_reader :text, :font_name, :font_size, :width_of_space, :direction

    # @param top [Float] top coordinate
    # @param left [Float] left coordinate
    # @param width [Float] width
    # @param height [Float] height
    # @param text [String] the text content
    # @param font_name [String] name of the font
    # @param font_size [Float] font size in points
    # @param width_of_space [Float] width of space character in this font
    # @param direction [Integer] text direction (LTR or RTL)
    def initialize(top:, left:, width:, height:, text:, font_name: nil, font_size: nil,
                   width_of_space: nil, direction: DIRECTION_LTR)
      super(top, left, width, height)
      @text = text
      @font_name = font_name
      @font_size = font_size&.to_f
      @width_of_space = width_of_space&.to_f
      @direction = direction
    end

    def ltr?
      direction == DIRECTION_LTR
    end

    def rtl?
      direction == DIRECTION_RTL
    end

    # Check if this element is whitespace
    def whitespace?
      text.nil? || text.strip.empty?
    end

    def to_s
      "TextElement[#{text.inspect}](#{left}, #{top}, #{width}, #{height})"
    end

    def inspect
      to_s
    end

    def ==(other)
      return false unless other.is_a?(TextElement)

      super && text == other.text && font_name == other.font_name &&
        font_size == other.font_size
    end
    alias eql? ==

    def hash
      [super, text, font_name, font_size].hash
    end

    class << self
      # Merge text elements into text chunks (words)
      # @param elements [Array<TextElement>] text elements to merge
      # @param vertical_rulings [Array<Ruling>] vertical rulings that act as word separators
      # @return [Array<TextChunk>] merged text chunks
      def merge_words(elements, vertical_rulings: [])
        return [] if elements.empty?

        chunks = []
        current_chunk = nil

        sorted = elements.reject(&:whitespace?).sort_by { |e| [e.top, e.left] }

        sorted.each do |element|
          if current_chunk.nil?
            current_chunk = TextChunk.new(element)
          elsif should_merge?(current_chunk, element, vertical_rulings)
            current_chunk.add(element)
          else
            chunks << current_chunk
            current_chunk = TextChunk.new(element)
          end
        end

        chunks << current_chunk if current_chunk
        chunks
      end

      private

      def should_merge?(chunk, element, vertical_rulings)
        return false unless chunk.vertically_overlaps?(element)

        # Check if there's a vertical ruling between them
        if vertical_rulings.any? { |r| ruling_between?(chunk, element, r) }
          return false
        end

        # Check horizontal gap
        gap = element.left - chunk.right
        max_gap = [chunk.width_of_space || chunk.width, element.width_of_space || element.width].compact.max
        max_gap ||= element.width

        gap <= max_gap * 0.5
      end

      def ruling_between?(chunk, element, ruling)
        return false unless ruling.vertical?

        ruling_x = ruling.x1
        ruling_x > chunk.right && ruling_x < element.left &&
          ruling.top <= [chunk.top, element.top].min &&
          ruling.bottom >= [chunk.bottom, element.bottom].max
      end
    end
  end
end
