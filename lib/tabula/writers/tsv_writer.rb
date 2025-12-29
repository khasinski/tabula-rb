# frozen_string_literal: true

module Tabula
  module Writers
    # Writes tables in TSV (Tab-Separated Values) format
    class TSVWriter < Writer
      # Write tables to an IO object
      # @param tables [Array<Table>] tables to write
      # @param io [IO] output destination
      def write(tables, io)
        tables.each_with_index do |table, idx|
          # Add blank line between tables
          io.puts if idx.positive?

          table.to_a.each do |row|
            # Escape tabs and newlines in cell values
            escaped = row.map { |cell| escape_value(cell) }
            io.puts escaped.join("\t")
          end
        end
      end

      private

      def escape_value(value)
        return "" if value.nil?

        value.to_s
             .gsub("\t", "\\t")
             .gsub("\n", "\\n")
             .gsub("\r", "\\r")
      end
    end
  end
end
