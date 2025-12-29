# frozen_string_literal: true

module Tabula
  module Writers
    # Base class for table output writers
    class Writer
      # Write tables to an IO object
      # @param tables [Array<Table>] tables to write
      # @param io [IO] output destination
      # @param options [Hash] writer-specific options
      def self.write(tables, io = $stdout, **options)
        new(**options).write(tables, io)
      end

      # Write tables to a string
      # @param tables [Array<Table>] tables to write
      # @param options [Hash] writer-specific options
      # @return [String] formatted output
      def self.to_string(tables, **options)
        require 'stringio'
        io = StringIO.new
        write(tables, io, **options)
        io.string
      end

      # @param options [Hash] writer options
      def initialize(**options)
        @options = options
      end

      # Write tables to an IO object
      # @param tables [Array<Table>] tables to write
      # @param io [IO] output destination
      def write(tables, io)
        raise NotImplementedError, 'Subclasses must implement #write'
      end
    end
  end
end
