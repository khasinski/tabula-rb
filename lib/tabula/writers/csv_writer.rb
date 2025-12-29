# frozen_string_literal: true

require "csv"

module Tabula
  module Writers
    # Writes tables in CSV format
    class CSVWriter < Writer
      # @param separator [String] field separator (default: comma)
      # @param quote_char [String] quote character (default: double quote)
      # @param force_quotes [Boolean] always quote fields (default: false)
      def initialize(separator: ",", quote_char: '"', force_quotes: false, **options)
        super(**options)
        @separator = separator
        @quote_char = quote_char
        @force_quotes = force_quotes
      end

      # Write tables to an IO object
      # @param tables [Array<Table>] tables to write
      # @param io [IO] output destination
      def write(tables, io)
        csv_options = {
          col_sep: @separator,
          quote_char: @quote_char,
          force_quotes: @force_quotes
        }

        tables.each_with_index do |table, idx|
          # Add blank line between tables
          io.puts if idx.positive?

          csv = CSV.new(io, **csv_options)
          table.to_a.each { |row| csv << row }
        end
      end

      # Write tables to a string
      # @param tables [Array<Table>] tables to write
      # @return [String] CSV formatted output
      def self.to_string(tables, **options)
        require "stringio"
        io = StringIO.new
        new(**options).write(tables, io)
        io.string
      end
    end
  end
end
