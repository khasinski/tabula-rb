# frozen_string_literal: true

module Tabula
  # Represents a cell in a table.
  # Contains text content and positional information.
  class Cell < Rectangle
    attr_reader :text_elements
    attr_accessor :placeholder

    # @param top [Float] top coordinate
    # @param left [Float] left coordinate
    # @param width [Float] cell width
    # @param height [Float] cell height
    # @param placeholder [Boolean] whether this is a placeholder cell
    def initialize(top, left, width, height, placeholder: false)
      super(top, left, width, height)
      @text_elements = []
      @placeholder = placeholder
    end

    # Create a cell from a rectangle
    # @param rect [Rectangle] rectangle to convert
    # @return [Cell]
    def self.from_rectangle(rect)
      new(rect.top, rect.left, rect.width, rect.height)
    end

    # Create an empty placeholder cell
    # @return [Cell]
    def self.empty
      new(0, 0, 0, 0, placeholder: true)
    end

    # Add a text element to this cell
    # @param element [TextElement, TextChunk] text to add
    def add(element)
      @text_elements << element
      self
    end

    # Add multiple text elements
    # @param elements [Array<TextElement, TextChunk>] elements to add
    def add_all(elements)
      elements.each { |e| add(e) }
      self
    end

    # Get cell text content
    # @param separator [String] separator between text elements
    # @return [String]
    def text(separator: " ")
      sorted = @text_elements.sort_by { |e| [e.top, e.left] }
      sorted.map do |e|
        e.respond_to?(:text) ? e.text : e.to_s
      end.join(separator).strip
    end

    # Check if cell has any text
    # @return [Boolean]
    def has_text?
      @text_elements.any?
    end

    # Check if cell is empty (no text elements)
    # @return [Boolean]
    def empty?
      @text_elements.empty?
    end

    # Check if cell is blank (empty or contains only whitespace)
    # @return [Boolean]
    def blank?
      return true if @text_elements.empty?

      # Check if all text content is just whitespace
      text.strip.empty?
    end

    # Check if this is a placeholder cell
    # @return [Boolean]
    def placeholder?
      @placeholder
    end

    # Check if this cell spans multiple rows/columns (stub for future use)
    # @return [Boolean]
    def spanning?
      false
    end

    def to_s
      "Cell[#{text.inspect}](#{left}, #{top}, #{width}, #{height})"
    end

    def inspect
      to_s
    end

    def ==(other)
      return false unless other.is_a?(Cell)

      super && text == other.text
    end
    alias eql? ==

    def hash
      [super, text].hash
    end
  end
end
