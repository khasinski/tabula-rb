# frozen_string_literal: true

module Tabula
  # Represents a group of text elements (typically a word or phrase).
  # Extends Rectangle to provide bounding box functionality.
  class TextChunk < Rectangle
    attr_reader :elements

    # @param element_or_rect [TextElement, Rectangle] initial element or bounds
    def initialize(element_or_rect = nil)
      if element_or_rect.is_a?(TextElement)
        super(element_or_rect.top, element_or_rect.left, element_or_rect.width, element_or_rect.height)
        @elements = [element_or_rect]
      elsif element_or_rect.is_a?(Rectangle)
        super(element_or_rect.top, element_or_rect.left, element_or_rect.width, element_or_rect.height)
        @elements = []
      elsif element_or_rect.nil?
        super(0, 0, 0, 0)
        @elements = []
      else
        raise ArgumentError, "Expected TextElement, Rectangle, or nil"
      end
    end

    # Add a text element to this chunk
    # @param element [TextElement] element to add
    def add(element)
      @elements << element
      merge!(element)
      self
    end

    # Add multiple elements
    # @param elements [Array<TextElement>] elements to add
    def add_all(elements)
      elements.each { |e| add(e) }
      self
    end

    # Get the combined text content
    # @param normalize [Boolean] whether to normalize whitespace
    # @return [String] the text content
    def text(normalize: true)
      # Sort elements based on text direction
      sorted = if ltr_dominant?
                 @elements.sort_by(&:left)
               else
                 @elements.sort_by(&:left).reverse
               end
      raw = sorted.map(&:text).join
      normalize ? raw.gsub(/\s+/, " ").strip : raw
    end

    # Check if this chunk is RTL dominant
    def rtl_dominant?
      !ltr_dominant?
    end

    # Get width of space character for this chunk
    def width_of_space
      @elements.map(&:width_of_space).compact.first
    end

    # Get font name
    def font_name
      @elements.first&.font_name
    end

    # Get font size
    def font_size
      @elements.first&.font_size
    end

    # Check if this chunk contains only a single repeated character
    # @param chars [Array<String>] characters to check for
    # @return [Boolean]
    def same_char?(chars)
      return false if @elements.empty?

      @elements.all? { |e| chars.include?(e.text) }
    end

    # Remove runs of identical characters
    # @param char [String] character to squeeze
    # @param min_run [Integer] minimum run length to squeeze
    # @return [TextChunk] new chunk with squeezed text
    def squeeze(char, min_run: 3)
      return self if @elements.size < min_run

      new_chunk = TextChunk.new(Rectangle.new(top, left, width, height))
      run_count = 0

      @elements.each do |element|
        if element.text == char
          run_count += 1
          new_chunk.add(element) if run_count <= 1
        else
          run_count = 0
          new_chunk.add(element)
        end
      end

      new_chunk
    end

    # Check if LTR text is dominant in this chunk
    def ltr_dominant?
      ltr_count = @elements.count(&:ltr?)
      rtl_count = @elements.count(&:rtl?)
      ltr_count >= rtl_count
    end

    # Split this chunk at an index
    # @param index [Integer] element index to split at
    # @return [Array<TextChunk>] two chunks, before and after the split
    def split_at(index)
      return [dup, TextChunk.new] if index >= @elements.size
      return [TextChunk.new, dup] if index <= 0

      left_chunk = TextChunk.new
      right_chunk = TextChunk.new

      @elements[0...index].each { |e| left_chunk.add(e) }
      @elements[index..].each { |e| right_chunk.add(e) }

      [left_chunk, right_chunk]
    end

    # Merge with another chunk
    # @param other [TextChunk] chunk to merge
    # @return [TextChunk] self
    def merge_chunk(other)
      other.elements.each { |e| add(e) }
      self
    end

    def to_s
      "TextChunk[#{text.inspect}](#{left}, #{top}, #{width}, #{height})"
    end

    def inspect
      to_s
    end

    def empty?
      @elements.empty?
    end

    def size
      @elements.size
    end

    class << self
      # Check if all chunks contain the same repeated character
      # @param chunks [Array<TextChunk>] chunks to check
      # @param chars [Array<String>] characters to check for
      # @return [Boolean]
      def all_same_char?(chunks, chars)
        chunks.all? { |c| c.same_char?(chars) }
      end

      # Group text chunks into lines
      # @param chunks [Array<TextChunk>] chunks to group
      # @return [Array<Line>] lines of text
      def group_by_lines(chunks)
        return [] if chunks.empty?

        sorted = chunks.sort_by { |c| [c.top, c.left] }
        lines = []
        current_line = Line.new

        sorted.each do |chunk|
          if current_line.empty? || current_line.vertically_overlaps?(chunk)
            current_line.add_chunk(chunk)
          else
            lines << current_line
            current_line = Line.new
            current_line.add_chunk(chunk)
          end
        end

        lines << current_line unless current_line.empty?
        lines
      end
    end
  end
end
