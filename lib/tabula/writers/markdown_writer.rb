# frozen_string_literal: true

module Tabula
  module Writers
    # Writes tables in Markdown format (GitHub-flavored)
    class MarkdownWriter < Writer
      # @param alignment [Symbol] column alignment (:left, :center, :right, or nil for default)
      def initialize(alignment: nil, **options)
        super(**options)
        @alignment = alignment
      end

      # Write tables to an IO object
      # @param tables [Array<Table>] tables to write
      # @param io [IO] output destination
      def write(tables, io)
        tables.each_with_index do |table, idx|
          # Add blank line between tables
          io.puts if idx.positive?

          rows = table.to_a
          next if rows.empty?

          col_count = rows.map(&:size).max || 0
          next if col_count.zero?

          # Write header row (first row)
          write_row(io, rows.first, col_count)

          # Write separator row
          write_separator(io, col_count)

          # Write data rows
          rows.drop(1).each do |row|
            write_row(io, row, col_count)
          end
        end
      end

      private

      def write_row(io, row, col_count)
        cells = (0...col_count).map do |i|
          escape_markdown(row[i].to_s)
        end
        io.puts "| #{cells.join(' | ')} |"
      end

      def write_separator(io, col_count)
        separators = Array.new(col_count) do
          case @alignment
          when :left
            ':---'
          when :center
            ':---:'
          when :right
            '---:'
          else
            '---'
          end
        end
        io.puts "| #{separators.join(' | ')} |"
      end

      def escape_markdown(text)
        # Escape pipe characters and normalize whitespace
        text.gsub('|', '\\|').gsub(/\s+/, ' ').strip
      end
    end
  end
end
