# frozen_string_literal: true

module Tabula
  # Represents a line of text (a row of text chunks).
  # Used for grouping text elements that share the same vertical position.
  class Line < Rectangle
    attr_reader :chunks

    def initialize
      super(0, 0, 0, 0)
      @chunks = []
      @initialized = false
    end

    # Add a text chunk to this line
    # @param chunk [TextChunk] chunk to add
    def add_chunk(chunk)
      @chunks << chunk
      if @initialized
        merge!(chunk)
      else
        @top = chunk.top
        @left = chunk.left
        @width = chunk.width
        @height = chunk.height
        @initialized = true
      end
      self
    end

    # Get chunks sorted by horizontal position
    # Respects RTL text direction when most chunks are RTL
    # @return [Array<TextChunk>] sorted chunks
    def sorted_chunks
      if rtl_dominant?
        @chunks.sort_by(&:left).reverse
      else
        @chunks.sort_by(&:left)
      end
    end

    # Check if this line is LTR dominant
    def ltr_dominant?
      return true if @chunks.empty?

      ltr_count = @chunks.count(&:ltr_dominant?)
      rtl_count = @chunks.count(&:rtl_dominant?)
      ltr_count >= rtl_count
    end

    # Check if this line is RTL dominant
    def rtl_dominant?
      !ltr_dominant?
    end

    # Get the combined text of all chunks
    # @param separator [String] separator between chunks
    # @return [String]
    def text(separator: " ")
      sorted_chunks.map(&:text).join(separator)
    end

    # Get text elements from all chunks
    # @return [Array<TextElement>]
    def text_elements
      @chunks.flat_map(&:elements)
    end

    # Average character width in this line
    # @return [Float]
    def average_char_width
      elements = text_elements
      return 0.0 if elements.empty?

      total_width = elements.sum(&:width)
      total_width / elements.size
    end

    # Check if a position falls within a gap between chunks
    # @param x [Float] horizontal position
    # @param min_gap [Float] minimum gap size
    # @return [Boolean]
    def in_gap?(x, min_gap: nil)
      min_gap ||= average_char_width * 0.5
      sorted = sorted_chunks

      sorted.each_cons(2) do |left_chunk, right_chunk|
        gap_start = left_chunk.right
        gap_end = right_chunk.left
        gap_size = gap_end - gap_start

        return true if x >= gap_start && x <= gap_end && gap_size >= min_gap
      end

      false
    end

    # Find gap positions between chunks
    # @param min_gap [Float] minimum gap size
    # @return [Array<Float>] gap center positions
    def gap_positions(min_gap: nil)
      min_gap ||= average_char_width * 2
      gaps = []
      sorted = sorted_chunks

      sorted.each_cons(2) do |left_chunk, right_chunk|
        gap_start = left_chunk.right
        gap_end = right_chunk.left
        gap_size = gap_end - gap_start

        gaps << (gap_start + gap_end) / 2.0 if gap_size >= min_gap
      end

      gaps
    end

    def empty?
      @chunks.empty?
    end

    def size
      @chunks.size
    end

    def to_s
      "Line[#{text.inspect}](#{left}, #{top}, #{width}, #{height})"
    end

    def inspect
      to_s
    end
  end
end
