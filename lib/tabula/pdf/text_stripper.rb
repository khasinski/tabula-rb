# frozen_string_literal: true

require "pdf-reader"

module Tabula
  # Extracts text elements from PDF pages using pdf-reader.
  # Captures character positions and font information.
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
      receiver = TextReceiver.new(@page)
      @page.walk(receiver)
      @text_elements = receiver.text_elements
      @min_char_width = receiver.min_char_width
      @min_char_height = receiver.min_char_height
      @text_elements
    end

    attr_reader :min_char_width, :min_char_height

    # Receiver for pdf-reader page walking
    # Captures text positioning callbacks
    class TextReceiver
      attr_reader :text_elements, :min_char_width, :min_char_height

      def initialize(page)
        @page = page
        @page_height = page.attributes[:MediaBox][3].to_f
        @text_elements = []
        @min_char_width = Float::INFINITY
        @min_char_height = Float::INFINITY

        @current_font = nil
        @current_font_size = nil
        @text_matrix = identity_matrix
        @ctm = identity_matrix
        @graphics_state_stack = []
      end

      # Called for each text run
      def show_text(string)
        return if string.nil? || string.empty?

        process_text(string)
      end

      # Called for each text run with positioning
      def show_text_with_positioning(array)
        array.each do |item|
          case item
          when String
            process_text(item)
          when Numeric
            # Adjust text position (negative = move right)
            adjust_text_position(-item / 1000.0 * @current_font_size)
          end
        end
      end

      # Font selection
      def set_text_font_and_size(font_name, size)
        @current_font = font_name
        @current_font_size = size.to_f
      end

      # Text matrix
      def set_text_matrix_and_text_line_matrix(a, b, c, d, e, f)
        @text_matrix = [[a, b, 0], [c, d, 0], [e, f, 1]]
        @text_line_matrix = @text_matrix.map(&:dup)
      end

      # Move to start of next line
      def move_text_position(tx, ty)
        translation = [[1, 0, 0], [0, 1, 0], [tx, ty, 1]]
        @text_line_matrix = matrix_multiply(translation, @text_line_matrix || identity_matrix)
        @text_matrix = @text_line_matrix.map(&:dup)
      end

      # CTM operations
      def concatenate_matrix(a, b, c, d, e, f)
        matrix = [[a, b, 0], [c, d, 0], [e, f, 1]]
        @ctm = matrix_multiply(matrix, @ctm)
      end

      def save_graphics_state
        @graphics_state_stack.push({
                                     ctm: @ctm.map(&:dup),
                                     font: @current_font,
                                     font_size: @current_font_size
                                   })
      end

      def restore_graphics_state
        state = @graphics_state_stack.pop
        return unless state

        @ctm = state[:ctm]
        @current_font = state[:font]
        @current_font_size = state[:font_size]
      end

      private

      def process_text(string)
        return if string.empty?

        # Get current transformation
        text_rendering_matrix = matrix_multiply(@text_matrix || identity_matrix, @ctm)

        # Calculate position in page coordinates
        x = text_rendering_matrix[2][0]
        y = @page_height - text_rendering_matrix[2][1] # Convert to top-left origin

        # Estimate character dimensions
        font_size = @current_font_size || 12.0
        scale_x = Math.sqrt(text_rendering_matrix[0][0]**2 + text_rendering_matrix[0][1]**2)
        scale_y = Math.sqrt(text_rendering_matrix[1][0]**2 + text_rendering_matrix[1][1]**2)

        char_height = font_size * scale_y
        avg_char_width = font_size * scale_x * 0.5 # Rough estimate

        # Create text elements for each character
        string.each_char.with_index do |char, i|
          char_x = x + (i * avg_char_width)
          char_width = avg_char_width

          element = TextElement.new(
            top: y - char_height,
            left: char_x,
            width: char_width,
            height: char_height,
            text: char,
            font_name: @current_font.to_s,
            font_size: font_size,
            width_of_space: avg_char_width
          )

          @text_elements << element
          @min_char_width = [char_width, @min_char_width].min if char_width.positive?
          @min_char_height = [char_height, @min_char_height].min if char_height.positive?
        end

        # Advance text position
        advance_text_position(string.length * avg_char_width)
      end

      def adjust_text_position(amount)
        return unless @text_matrix

        @text_matrix[2][0] += amount
      end

      def advance_text_position(amount)
        return unless @text_matrix

        @text_matrix[2][0] += amount
      end

      def identity_matrix
        [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
      end

      def matrix_multiply(a, b)
        result = Array.new(3) { Array.new(3, 0.0) }
        3.times do |i|
          3.times do |j|
            3.times do |k|
              result[i][j] += a[i][k] * b[k][j]
            end
          end
        end
        result
      end
    end
  end
end
