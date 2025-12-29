# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_group 'Core', 'lib/tabula/core'
  add_group 'Text', 'lib/tabula/text'
  add_group 'Table', 'lib/tabula/table'
  add_group 'PDF', 'lib/tabula/pdf'
  add_group 'Extractors', 'lib/tabula/extractors'
  add_group 'Detectors', 'lib/tabula/detectors'
  add_group 'Writers', 'lib/tabula/writers'
  add_group 'Algorithms', 'lib/tabula/algorithms'
end

require 'tabula'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end

# Helper to get fixture path
def fixture_path(name)
  File.join(__dir__, 'fixtures', name)
end

# Helper to load fixture PDF
def fixture_pdf(name)
  fixture_path("pdf/#{name}.pdf")
end

# Helper to load expected CSV
def fixture_csv(name)
  path = fixture_path("csv/#{name}.csv")
  File.read(path, encoding: 'UTF-8')
end

# Helper to load expected JSON
def fixture_json(name)
  path = fixture_path("json/#{name}.json")
  File.read(path, encoding: 'UTF-8')
end

# Test utilities matching tabula-java's UtilsForTesting
module TestUtils
  module_function

  # Get an area from the first page of a PDF
  # @param path [String] path to PDF
  # @param top [Float] top coordinate
  # @param left [Float] left coordinate
  # @param bottom [Float] bottom coordinate
  # @param right [Float] right coordinate
  # @return [Tabula::Page] page area
  def get_area_from_first_page(path, top, left, bottom, right)
    get_area_from_page(path, 1, top, left, bottom, right)
  end

  # Get an area from a specific page of a PDF
  # @param path [String] path to PDF
  # @param page_number [Integer] page number (1-indexed)
  # @param top [Float] top coordinate
  # @param left [Float] left coordinate
  # @param bottom [Float] bottom coordinate
  # @param right [Float] right coordinate
  # @return [Tabula::Page] page area
  def get_area_from_page(path, page_number, top, left, bottom, right)
    page = get_page(path, page_number)
    page.get_area(top, left, bottom, right)
  end

  # Get a specific page from a PDF
  # @param path [String] path to PDF
  # @param page_number [Integer] page number (1-indexed)
  # @return [Tabula::Page] page
  def get_page(path, page_number)
    extractor = Tabula::ObjectExtractor.new(path)
    extractor.extract_page(page_number)
  end

  # Convert table to array of rows (array of arrays of strings)
  # @param table [Tabula::Table] table
  # @return [Array<Array<String>>] 2D string array
  def table_to_array_of_rows(table)
    table.rows.map do |row|
      row.map(&:text)
    end
  end

  # Load CSV fixture content with normalized line endings
  # @param path [String] path to CSV file
  # @return [String] CSV content
  def load_csv(path)
    content = File.read(path, encoding: 'UTF-8')
    # Normalize to CRLF like Java version
    content.gsub(/(?<!\r)\n/, "\r")
  end

  # Load JSON fixture content
  # @param path [String] path to JSON file
  # @return [String] JSON content
  def load_json(path)
    File.read(path, encoding: 'UTF-8')
  end
end
