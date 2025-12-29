# frozen_string_literal: true

module Tabula
  module Extractors
    # Base class for table extraction algorithms
    class ExtractionAlgorithm
      # Extract tables from a page
      # @param page [Page] page to extract from
      # @param options [Hash] algorithm-specific options
      # @return [Array<Table>] extracted tables
      def self.extract(page, **options)
        new(**options).extract(page)
      end

      # @param options [Hash] algorithm options
      def initialize(**options)
        @options = options
      end

      # Extract tables from a page
      # @param page [Page] page to extract from
      # @return [Array<Table>]
      def extract(page)
        raise NotImplementedError, "Subclasses must implement #extract"
      end

      # Get algorithm name for table metadata
      # @return [String]
      def name
        self.class.name.split("::").last
      end
    end
  end
end
