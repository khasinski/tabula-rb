# frozen_string_literal: true

module Tabula
  # Represents a PDF page with extracted text elements and rulings.
  # Provides methods for accessing page content and creating sub-areas.
  class Page < Rectangle
    attr_reader :page_number, :rotation, :text_elements, :rulings,
                :min_char_width, :min_char_height, :spatial_index

    # @param top [Float] top coordinate
    # @param left [Float] left coordinate
    # @param width [Float] page width
    # @param height [Float] page height
    # @param page_number [Integer] page number (1-indexed)
    # @param rotation [Integer] page rotation in degrees
    # @param text_elements [Array<TextElement>] extracted text elements
    # @param rulings [Array<Ruling>] extracted ruling lines
    # @param min_char_width [Float] minimum character width
    # @param min_char_height [Float] minimum character height
    def initialize(top:, left:, width:, height:, page_number:, rotation: 0,
                   text_elements: [], rulings: [], min_char_width: nil, min_char_height: nil)
      super(top, left, width, height)
      @page_number = page_number
      @rotation = rotation
      @text_elements = text_elements
      @rulings = rulings
      @min_char_width = min_char_width
      @min_char_height = min_char_height
      @spatial_index = build_spatial_index
      @processed_rulings = nil
    end

    # Get text elements within a rectangular area
    # @param area [Rectangle] area to query
    # @return [Array<TextElement>]
    def get_text(area = nil)
      return @text_elements if area.nil?

      # Use intersects because text elements may extend beyond cell boundaries
      # (e.g., text with descenders or tall characters)
      # Filter to elements whose origin (top-left) is within the area
      @spatial_index.intersects(area).select do |te|
        te.top >= area.top && te.top < area.bottom &&
          te.left >= area.left && te.left < area.right
      end
    end

    # Get the bounding box of all text on the page
    # @return [Rectangle, nil]
    def text_bounds
      Rectangle.bounding_box_of(@text_elements)
    end

    # Create a sub-page for a specific area
    # @param top [Float] area top
    # @param left [Float] area left
    # @param bottom [Float] area bottom
    # @param right [Float] area right
    # @return [Page] sub-page containing only elements in the area
    def get_area(top, left, bottom, right)
      area = Rectangle.from_bounds(top, left, bottom, right)

      # Filter text elements
      area_elements = get_text(area)

      # Filter and clip rulings
      area_rulings = Ruling.crop_to_area(rulings, area)

      Page.new(
        top: top,
        left: left,
        width: right - left,
        height: bottom - top,
        page_number: page_number,
        rotation: rotation,
        text_elements: area_elements,
        rulings: area_rulings,
        min_char_width: min_char_width,
        min_char_height: min_char_height
      )
    end

    # Get processed ruling lines (collapsed and cleaned)
    # @return [Array<Ruling>]
    def get_rulings
      @processed_rulings ||= process_rulings
    end

    # Get horizontal ruling lines
    # @return [Array<Ruling>]
    def horizontal_rulings
      get_rulings.select(&:horizontal?)
    end

    # Get vertical ruling lines
    # @return [Array<Ruling>]
    def vertical_rulings
      get_rulings.select(&:vertical?)
    end

    # Get raw (unprocessed) rulings
    # @return [Array<Ruling>]
    def unprocessed_rulings
      @rulings
    end

    # Add a ruling to the page
    # @param ruling [Ruling] ruling to add
    def add_ruling(ruling)
      return if ruling.oblique?

      @rulings << ruling
      @processed_rulings = nil # Invalidate cache
    end

    # Check if page has ruling lines
    # @return [Boolean]
    def has_rulings?
      !@rulings.empty?
    end

    # Get text chunks (words) from the page
    # @return [Array<TextChunk>]
    def text_chunks
      TextElement.merge_words(@text_elements, vertical_rulings: vertical_rulings)
    end

    # Get lines of text
    # @return [Array<Line>]
    def text_lines
      TextChunk.group_by_lines(text_chunks)
    end

    def to_s
      "Page[#{page_number}](#{left}, #{top}, #{width}, #{height})"
    end

    def inspect
      to_s
    end

    private

    def build_spatial_index
      index = SpatialIndex.new
      index.add_all(@text_elements)
      index
    end

    def process_rulings
      # Remove oblique lines
      clean = @rulings.reject(&:oblique?)

      # Collapse colinear rulings
      Ruling.collapse_oriented_rulings(clean)
    end

    # Builder class for constructing Page objects
    class Builder
      def initialize
        @attrs = {
          top: 0,
          left: 0,
          width: 0,
          height: 0,
          page_number: 1,
          rotation: 0,
          text_elements: [],
          rulings: [],
          min_char_width: nil,
          min_char_height: nil
        }
      end

      def top(value)
        @attrs[:top] = value
        self
      end

      def left(value)
        @attrs[:left] = value
        self
      end

      def width(value)
        @attrs[:width] = value
        self
      end

      def height(value)
        @attrs[:height] = value
        self
      end

      def page_number(value)
        @attrs[:page_number] = value
        self
      end

      def rotation(value)
        @attrs[:rotation] = value
        self
      end

      def text_elements(value)
        @attrs[:text_elements] = value
        self
      end

      def rulings(value)
        @attrs[:rulings] = value
        self
      end

      def min_char_width(value)
        @attrs[:min_char_width] = value
        self
      end

      def min_char_height(value)
        @attrs[:min_char_height] = value
        self
      end

      def build
        Page.new(**@attrs)
      end
    end
  end
end
