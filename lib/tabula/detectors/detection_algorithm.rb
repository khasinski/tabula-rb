# frozen_string_literal: true

module Tabula
  module Detectors
    # Base class for table detection algorithms
    class DetectionAlgorithm
      # Detect table areas on a page
      # @param page [Page] page to detect tables on
      # @param options [Hash] algorithm-specific options
      # @return [Array<Rectangle>] detected table areas
      def self.detect(page, **options)
        new(**options).detect(page)
      end

      # @param options [Hash] algorithm options
      def initialize(**options)
        @options = options
      end

      # Detect table areas on a page
      # @param page [Page] page to detect tables on
      # @return [Array<Rectangle>]
      def detect(page)
        raise NotImplementedError, "Subclasses must implement #detect"
      end

      # Get algorithm name
      # @return [String]
      def name
        self.class.name.split("::").last
      end
    end
  end
end
