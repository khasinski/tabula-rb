# frozen_string_literal: true

module Tabula
  # Represents an extracted table with rows and cells.
  # Provides methods for accessing table data and converting to various formats.
  class Table < Rectangle
    attr_reader :extraction_method, :page_number

    # @param extraction_method [String] method used for extraction
    # @param page_number [Integer] page number where table was found
    def initialize(extraction_method: 'unknown', page_number: nil)
      super(0, 0, 0, 0)
      @extraction_method = extraction_method
      @page_number = page_number
      @cells = {} # { [row, col] => Cell }
      @row_count = 0
      @col_count = 0
      @memoized_rows = nil
    end

    # Add a cell at a specific position
    # @param row [Integer] row index (0-based)
    # @param col [Integer] column index (0-based)
    # @param cell [Cell] cell to add
    def add(row, col, cell)
      @cells[[row, col]] = cell
      @row_count = [row + 1, @row_count].max
      @col_count = [col + 1, @col_count].max
      @memoized_rows = nil # Invalidate cache

      # Update bounds
      if @cells.size == 1
        @top = cell.top
        @left = cell.left
        @width = cell.width
        @height = cell.height
      else
        merge!(cell)
      end

      self
    end

    # Get a cell at a specific position
    # @param row [Integer] row index
    # @param col [Integer] column index
    # @return [Cell] cell at position, or empty cell if none
    def get_cell(row, col)
      @cells[[row, col]] || Cell.empty
    end

    alias [] get_cell

    # Get number of rows
    # @return [Integer]
    attr_reader :row_count

    # Get number of columns
    # @return [Integer]
    attr_reader :col_count

    # Get all rows as 2D array
    # @return [Array<Array<Cell>>]
    def rows
      @rows ||= compute_rows
    end

    # Get all cells as flat array
    # @return [Array<Cell>]
    def cells
      @cells.values
    end

    # Get a specific row
    # @param index [Integer] row index
    # @return [Array<Cell>]
    def row(index)
      rows[index] || []
    end

    # Get a specific column
    # @param index [Integer] column index
    # @return [Array<Cell>]
    def column(index)
      rows.map { |r| r[index] || Cell.empty }
    end

    # Convert to 2D array of strings
    # @return [Array<Array<String>>]
    def to_a
      rows.map { |row| row.map(&:text) }
    end

    # Convert to CSV string
    # @param options [Hash] options for CSV generation
    # @return [String]
    def to_csv(**options)
      require 'csv'
      CSV.generate(**options) do |csv|
        to_a.each { |row| csv << row }
      end
    end

    # Convert to TSV string
    # @return [String]
    def to_tsv
      to_a.map { |row| row.join("\t") }.join("\n")
    end

    # Convert to hash (for JSON serialization)
    # @return [Hash]
    def to_h
      {
        extraction_method: @extraction_method,
        page_number: @page_number,
        top: top,
        left: left,
        width: width,
        height: height,
        data: to_a
      }
    end

    # Convert to JSON string
    # @return [String]
    def to_json(*args)
      require 'json'
      to_h.to_json(*args)
    end

    # Check if table is empty
    # @return [Boolean]
    def empty?
      @cells.empty?
    end

    # Iterate over rows
    # @yield [Array<Cell>] each row
    def each_row(&)
      rows.each(&)
    end

    # Iterate over cells
    # @yield [Integer, Integer, Cell] row, col, cell
    def each_cell
      rows.each_with_index do |row, row_idx|
        row.each_with_index do |cell, col_idx|
          yield row_idx, col_idx, cell
        end
      end
    end

    def to_s
      "Table[#{row_count}x#{col_count}](#{left}, #{top}, #{width}, #{height})"
    end

    def inspect
      to_s
    end

    private

    def compute_rows
      result = Array.new(@row_count) { Array.new(@col_count) { Cell.empty } }

      @cells.each do |(row, col), cell|
        result[row][col] = cell
      end

      result
    end

    # Table with ruling lines - extends Table with ruling information
    class WithRulingLines < Table
      attr_reader :horizontal_rulings, :vertical_rulings

      def initialize(horizontal_rulings: [], vertical_rulings: [], **kwargs)
        super(**kwargs)
        @horizontal_rulings = horizontal_rulings
        @vertical_rulings = vertical_rulings
      end
    end
  end
end
