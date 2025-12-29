# frozen_string_literal: true

require_relative "tabula/version"
require_relative "tabula/configuration"

# Core geometry
require_relative "tabula/core/point"
require_relative "tabula/core/rectangle"
require_relative "tabula/core/ruling"
require_relative "tabula/core/spatial_index"

# Text handling
require_relative "tabula/text/text_element"
require_relative "tabula/text/text_chunk"
require_relative "tabula/text/line"

# Table structures
require_relative "tabula/table/cell"
require_relative "tabula/table/table"

# PDF processing
require_relative "tabula/pdf/page"
require_relative "tabula/pdf/text_stripper"
require_relative "tabula/pdf/object_extractor"

# Extraction algorithms
require_relative "tabula/extractors/extraction_algorithm"
require_relative "tabula/extractors/basic_extraction_algorithm"
require_relative "tabula/extractors/spreadsheet_extraction_algorithm"

# Detection algorithms
require_relative "tabula/detectors/detection_algorithm"
require_relative "tabula/detectors/spreadsheet_detection_algorithm"
require_relative "tabula/detectors/nurminen_detection_algorithm"

# Writers
require_relative "tabula/writers/writer"
require_relative "tabula/writers/csv_writer"
require_relative "tabula/writers/tsv_writer"
require_relative "tabula/writers/json_writer"

# Geometric algorithms
require_relative "tabula/algorithms/cohen_sutherland_clipping"
require_relative "tabula/algorithms/projection_profile"

module Tabula
  class Error < StandardError; end
  class InvalidPDFError < Error; end
  class PasswordRequiredError < Error; end
  class FileNotFoundError < Error; end
  class InvalidOptionsError < Error; end

  VALID_METHODS = %i[lattice stream auto].freeze

  class << self
    # Extract tables from a PDF file
    #
    # @param path [String] path to PDF file
    # @param options [Hash] extraction options
    # @option options [Array<Integer>] :pages pages to extract (1-indexed, nil for all)
    # @option options [Symbol] :method extraction method (:lattice, :stream, or :auto)
    # @option options [Array<Float>] :area area to extract [top, left, bottom, right]
    # @option options [Array<Float>] :columns column boundaries
    # @option options [String] :password PDF password
    # @option options [Boolean] :guess auto-detect table areas
    # @return [Array<Table>] extracted tables
    # @raise [FileNotFoundError] if the file does not exist
    # @raise [InvalidOptionsError] if options are invalid
    def extract(path, **options)
      validate_file!(path)
      validate_options!(options)

      ObjectExtractor.open(path, password: options[:password]) do |extractor|
        pages = options[:pages] || (1..extractor.page_count).to_a
        method = options[:method] || :auto
        area = options[:area]
        columns = options[:columns]
        guess = options.fetch(:guess, false)

        tables = []

        pages.each do |page_num|
          page = extractor.extract_page(page_num)
          page = page.get_area(*area) if area

          if guess
            detected_areas = Detectors::Nurminen.detect(page)
            detected_areas.each do |detected_area|
              sub_page = page.get_area(*detected_area.bounds)
              tables.concat(extract_from_page(sub_page, method, columns))
            end
          else
            tables.concat(extract_from_page(page, method, columns))
          end
        end

        tables
      end
    end

    private

    def validate_file!(path)
      raise FileNotFoundError, "File not found: #{path}" unless File.exist?(path)
    end

    def validate_options!(options)
      validate_pages!(options[:pages]) if options[:pages]
      validate_area!(options[:area]) if options[:area]
      validate_method!(options[:method]) if options[:method]
    end

    def validate_pages!(pages)
      unless pages.is_a?(Array)
        raise InvalidOptionsError, "Pages must be an array, got #{pages.class}"
      end

      pages.each do |page|
        unless page.is_a?(Integer) && page.positive?
          raise InvalidOptionsError, "Page numbers must be positive integers, got #{page.inspect}"
        end
      end
    end

    def validate_area!(area)
      unless area.is_a?(Array) && area.size == 4
        raise InvalidOptionsError, "Area must be an array of exactly 4 values [top, left, bottom, right], got #{area.inspect}"
      end

      area.each_with_index do |value, index|
        labels = %w[top left bottom right]
        unless value.is_a?(Numeric)
          raise InvalidOptionsError, "Area #{labels[index]} must be numeric, got #{value.inspect}"
        end
      end
    end

    def validate_method!(method)
      unless VALID_METHODS.include?(method)
        raise InvalidOptionsError, "Method must be one of #{VALID_METHODS.map(&:inspect).join(', ')}, got #{method.inspect}"
      end
    end

    def extract_from_page(page, method, columns)
      case method
      when :lattice
        Extractors::Spreadsheet.extract(page)
      when :stream
        Extractors::Basic.extract(page, columns: columns)
      when :auto
        # Try lattice first, fall back to stream
        tables = Extractors::Spreadsheet.extract(page)
        tables.empty? ? Extractors::Basic.extract(page, columns: columns) : tables
      else
        raise ArgumentError, "Unknown extraction method: #{method}"
      end
    end
  end
end
