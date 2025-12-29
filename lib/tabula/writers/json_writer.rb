# frozen_string_literal: true

require 'json'

module Tabula
  module Writers
    # Writes tables in JSON format
    class JSONWriter < Writer
      # @param pretty [Boolean] pretty-print JSON (default: false)
      # @param include_metadata [Boolean] include table metadata (default: true)
      def initialize(pretty: false, include_metadata: true, **options)
        super(**options)
        @pretty = pretty
        @include_metadata = include_metadata
      end

      # Write tables to an IO object
      # @param tables [Array<Table>] tables to write
      # @param io [IO] output destination
      def write(tables, io)
        output = tables.map { |table| table_to_hash(table) }

        if @pretty
          io.puts JSON.pretty_generate(output)
        else
          io.puts JSON.generate(output)
        end
      end

      private

      def table_to_hash(table)
        if @include_metadata
          table.to_h
        else
          { data: table.to_a }
        end
      end
    end
  end
end
