# frozen_string_literal: true

require "pdf-reader"

module Tabula
  # Extracts content from PDF documents.
  # Wraps pdf-reader and provides access to pages with text and rulings.
  class ObjectExtractor
    attr_reader :pdf_reader

    # Open a PDF file for extraction
    # @param path [String] path to PDF file
    # @param password [String, nil] password for encrypted PDFs
    # @yield [ObjectExtractor] yields extractor for block usage
    # @return [ObjectExtractor, Object] extractor or block result
    def self.open(path, password: nil, &block)
      extractor = new(path, password: password)
      if block
        begin
          yield extractor
        ensure
          extractor.close
        end
      else
        extractor
      end
    end

    # @param path [String] path to PDF file
    # @param password [String, nil] password for encrypted PDFs
    def initialize(path, password: nil)
      @path = path
      @password = password
      @pdf_reader = open_pdf
      @closed = false
    end

    # Extract a specific page
    # @param page_number [Integer] page number (1-indexed)
    # @return [Page] extracted page
    def extract_page(page_number)
      validate_page_number(page_number)

      pdf_page = @pdf_reader.pages[page_number - 1]
      process_page(pdf_page, page_number)
    end

    # Extract all pages
    # @return [PageIterator] iterator over pages
    def extract
      extract_pages(1..page_count)
    end

    # Extract specific pages
    # @param pages [Range, Array<Integer>] page numbers to extract
    # @return [PageIterator] iterator over pages
    def extract_pages(pages)
      PageIterator.new(self, pages.to_a)
    end

    # Get page count
    # @return [Integer]
    def page_count
      @pdf_reader.page_count
    end

    # Get pages iterator
    # @return [Enumerator]
    def pages
      (1..page_count).lazy.map { |n| extract_page(n) }
    end

    # Close the PDF
    def close
      @closed = true
    end

    def closed?
      @closed
    end

    private

    def open_pdf
      PDF::Reader.new(@path, password: @password)
    rescue PDF::Reader::EncryptedPDFError
      raise PasswordRequiredError, "PDF is encrypted and requires a password"
    rescue PDF::Reader::MalformedPDFError => e
      raise InvalidPDFError, "Invalid PDF file: #{e.message}"
    end

    def validate_page_number(page_number)
      return if page_number >= 1 && page_number <= page_count

      raise ArgumentError, "Page number #{page_number} out of range (1-#{page_count})"
    end

    def process_page(pdf_page, page_number)
      # Get page dimensions
      media_box = pdf_page.attributes[:MediaBox]
      page_width = media_box[2].to_f - media_box[0].to_f
      page_height = media_box[3].to_f - media_box[1].to_f

      # Handle rotation
      rotation = pdf_page.attributes[:Rotate] || 0
      if rotation == 90 || rotation == 270
        page_width, page_height = page_height, page_width
      end

      # Extract text
      stripper = TextStripper.new(pdf_page)
      text_elements = stripper.extract

      # Extract rulings
      rulings = extract_rulings(pdf_page, page_height)

      # Build page object
      Page::Builder.new
                   .top(0)
                   .left(0)
                   .width(page_width)
                   .height(page_height)
                   .page_number(page_number)
                   .rotation(rotation)
                   .text_elements(text_elements)
                   .rulings(rulings)
                   .min_char_width(stripper.min_char_width)
                   .min_char_height(stripper.min_char_height)
                   .build
    end

    def extract_rulings(pdf_page, page_height)
      receiver = RulingReceiver.new(page_height)
      pdf_page.walk(receiver)
      receiver.rulings
    end

    # Receiver for extracting ruling lines from PDF graphics
    class RulingReceiver
      attr_reader :rulings

      def initialize(page_height)
        @page_height = page_height
        @rulings = []
        @current_path = []
        @ctm = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
        @graphics_state_stack = []
      end

      # Path construction
      def begin_new_subpath(x, y)
        @current_path = [[transform_point(x, y), :move]]
      end

      def append_line(x, y)
        @current_path << [transform_point(x, y), :line]
      end

      def append_rectangle(x, y, width, height)
        # Convert rectangle to four lines
        p1 = transform_point(x, y)
        p2 = transform_point(x + width, y)
        p3 = transform_point(x + width, y + height)
        p4 = transform_point(x, y + height)

        @current_path = [
          [p1, :move],
          [p2, :line],
          [p3, :line],
          [p4, :line],
          [p1, :line]
        ]
      end

      # Path painting
      def stroke_path
        extract_lines_from_path
        @current_path = []
      end

      def fill_path_with_nonzero
        extract_lines_from_path
        @current_path = []
      end

      def fill_path_with_even_odd
        extract_lines_from_path
        @current_path = []
      end

      def close_and_stroke_path
        close_path
        stroke_path
      end

      def close_fill_stroke
        close_path
        stroke_path
      end

      def end_path
        @current_path = []
      end

      def close_path
        return if @current_path.empty?

        first_point = @current_path.first[0]
        @current_path << [first_point, :line]
      end

      # CTM operations
      def concatenate_matrix(a, b, c, d, e, f)
        matrix = [[a, b, 0], [c, d, 0], [e, f, 1]]
        @ctm = matrix_multiply(matrix, @ctm)
      end

      def save_graphics_state
        @graphics_state_stack.push(@ctm.map(&:dup))
      end

      def restore_graphics_state
        @ctm = @graphics_state_stack.pop || [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
      end

      private

      def transform_point(x, y)
        tx = @ctm[0][0] * x + @ctm[1][0] * y + @ctm[2][0]
        ty = @ctm[0][1] * x + @ctm[1][1] * y + @ctm[2][1]
        # Convert to top-left origin
        [@page_height - ty, tx]
      end

      def extract_lines_from_path
        return if @current_path.size < 2

        @current_path.each_cons(2) do |(p1, _), (p2, type)|
          next unless type == :line

          y1, x1 = p1
          y2, x2 = p2

          # Only keep horizontal and vertical lines
          ruling = Ruling.new(x1, y1, x2, y2)
          @rulings << ruling unless ruling.oblique?
        end
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

  # Iterator for pages
  class PageIterator
    include Enumerable

    def initialize(extractor, page_numbers)
      @extractor = extractor
      @page_numbers = page_numbers
    end

    def each(&block)
      return enum_for(:each) unless block

      @page_numbers.each do |page_number|
        yield @extractor.extract_page(page_number)
      end
    end

    def size
      @page_numbers.size
    end
  end
end
