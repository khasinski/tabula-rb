# frozen_string_literal: true

require 'pdf-reader'

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
      raise PasswordRequiredError, 'PDF is encrypted and requires a password'
    rescue PDF::Reader::MalformedPDFError => e
      raise InvalidPDFError, "Invalid PDF file: #{e.message}"
    end

    def validate_page_number(page_number)
      return if page_number.between?(1, page_count)

      raise ArgumentError, "Page number #{page_number} out of range (1-#{page_count})"
    end

    def process_page(pdf_page, page_number)
      # Get page boxes
      media_box = pdf_page.attributes[:MediaBox]
      crop_box = pdf_page.attributes[:CropBox]
      has_crop_box = !crop_box.nil?
      crop_box ||= media_box

      # Calculate MediaBox dimensions (always positive)
      media_height = (media_box[3].to_f - media_box[1].to_f).abs

      # Detect if Y-axis is inverted (negative height in MediaBox)
      y_inverted = media_box[3].to_f < media_box[1].to_f

      # Calculate CropBox dimensions and offsets
      crop_left = [crop_box[0].to_f, crop_box[2].to_f].min
      crop_bottom = [crop_box[1].to_f, crop_box[3].to_f].min
      crop_right = [crop_box[0].to_f, crop_box[2].to_f].max
      crop_top = [crop_box[1].to_f, crop_box[3].to_f].max

      page_width = crop_right - crop_left
      page_height = crop_top - crop_bottom

      # Handle rotation
      rotation = pdf_page.attributes[:Rotate] || 0
      page_width, page_height = page_height, page_width if [90, 270].include?(rotation)

      # Extract text
      stripper = TextStripper.new(pdf_page)
      text_elements = stripper.extract

      # Extract rulings
      rulings = extract_rulings(pdf_page, media_height, y_inverted: y_inverted)

      # Only transform coordinates if there's a CropBox that differs from MediaBox
      if has_crop_box
        text_elements = transform_to_crop_space(text_elements, media_height, crop_left, crop_bottom, crop_top,
                                                y_inverted)
        rulings = transform_rulings_to_crop_space(rulings, media_height, crop_left, crop_bottom, crop_top, y_inverted)
      end

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

    def extract_rulings(pdf_page, page_height, y_inverted:)
      receiver = RulingReceiver.new(page_height, y_inverted: y_inverted)
      pdf_page.walk(receiver)
      receiver.rulings
    end

    def transform_to_crop_space(text_elements, media_height, crop_left, _crop_bottom, crop_top, _y_inverted)
      # Transform text element coordinates from MediaBox to CropBox space
      text_elements.map do |te|
        # Calculate Y offset in top-left coordinate system
        # In MediaBox space: top of crop area is at (media_height - crop_top)
        y_offset = media_height - crop_top
        new_top = te.top - y_offset
        new_left = te.left - crop_left

        TextElement.new(
          top: new_top,
          left: new_left,
          width: te.width,
          height: te.height,
          text: te.text,
          font_name: te.font_name,
          font_size: te.font_size,
          width_of_space: te.width_of_space
        )
      end
    end

    def transform_rulings_to_crop_space(rulings, media_height, crop_left, _crop_bottom, crop_top, _y_inverted)
      # Transform ruling coordinates from MediaBox to CropBox space
      y_offset = media_height - crop_top

      rulings.map do |r|
        new_y1 = r.y1 - y_offset
        new_y2 = r.y2 - y_offset
        new_x1 = r.x1 - crop_left
        new_x2 = r.x2 - crop_left

        Ruling.new(new_x1, new_y1, new_x2, new_y2)
      end
    end

    # Receiver for extracting ruling lines from PDF graphics
    class RulingReceiver
      attr_reader :rulings

      def initialize(page_height, y_inverted: false)
        @page_height = page_height
        @y_inverted = y_inverted
        @rulings = []
        @current_path = []
        @subpaths = [] # Collect all subpaths for filling
        @ctm = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
        @graphics_state_stack = []
      end

      # Path construction
      def begin_new_subpath(x, y)
        # Save current subpath if it has content
        @subpaths << @current_path.dup if @current_path.any?
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
        # Include current path
        @subpaths << @current_path.dup if @current_path.any?

        # Process all subpaths
        @subpaths.each do |subpath|
          @current_path = subpath
          extract_rulings_from_filled_path
        end

        @current_path = []
        @subpaths = []
      end

      def fill_path_with_even_odd
        # Include current path
        @subpaths << @current_path.dup if @current_path.any?

        # Process all subpaths
        @subpaths.each do |subpath|
          @current_path = subpath
          extract_rulings_from_filled_path
        end

        @current_path = []
        @subpaths = []
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
        tx = (@ctm[0][0] * x) + (@ctm[1][0] * y) + @ctm[2][0]
        ty = (@ctm[0][1] * x) + (@ctm[1][1] * y) + @ctm[2][1]
        # Convert to top-left origin, handling inverted coordinate systems
        if @y_inverted
          [ty.abs, tx]
        else
          [@page_height - ty, tx]
        end
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

      def extract_rulings_from_filled_path
        return if @current_path.size < 4

        # Get bounding box of the path
        points = @current_path.map { |p, _| p }
        y_coords = points.map { |p| p[0] }
        x_coords = points.map { |p| p[1] }

        min_y = y_coords.min
        max_y = y_coords.max
        min_x = x_coords.min
        max_x = x_coords.max

        width = max_x - min_x
        height = max_y - min_y

        # Threshold for considering a filled rectangle as a ruling line
        # If one dimension is much smaller than the other, treat it as a line
        ruling_threshold = 8.0

        if height <= ruling_threshold && width > ruling_threshold
          # Horizontal ruling
          mid_y = (min_y + max_y) / 2.0
          @rulings << Ruling.new(min_x, mid_y, max_x, mid_y)
        elsif width <= ruling_threshold && height > ruling_threshold
          # Vertical ruling
          mid_x = (min_x + max_x) / 2.0
          @rulings << Ruling.new(mid_x, min_y, mid_x, max_y)
        end
        # Otherwise, ignore (it's a filled area, not a line)
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
