# frozen_string_literal: true

module Tabula
  # Configuration class for customizable extraction parameters.
  # All thresholds can be adjusted to tune extraction behavior.
  class Configuration
    # --- Ruling Detection ---

    # Tolerance for determining if a ruling is horizontal or vertical (in points)
    # Lines with less than this difference in position are considered aligned
    attr_accessor :orientation_tolerance

    # Tolerance for ruling intersection detection (in points)
    attr_accessor :intersection_tolerance

    # Maximum thickness of a filled rectangle to be treated as a ruling line (in points)
    attr_accessor :ruling_thickness_threshold

    # --- Text Element Merging ---

    # Multiplier for space width when determining word boundaries
    # Lower values = more aggressive word merging
    attr_accessor :word_gap_multiplier

    # Multiplier for determining line boundaries
    attr_accessor :line_gap_multiplier

    # --- Cell Detection ---

    # Minimum number of cells required for a valid table
    attr_accessor :min_cells

    # Minimum dimension (width or height) for a valid table region (in points)
    attr_accessor :min_table_dimension

    # Tolerance for cell corner detection (in points)
    attr_accessor :cell_tolerance

    # --- Table Detection ---

    # Minimum number of rows required for table detection
    attr_accessor :min_rows

    # Overlap threshold for merging duplicate table detections
    attr_accessor :overlap_threshold

    # Threshold for determining if a table has valid row/column ratio
    attr_accessor :tabular_ratio_threshold

    # Tolerance for clustering text edges during detection (in points)
    attr_accessor :edge_clustering_tolerance

    # Padding around detected table areas (in points)
    attr_accessor :detection_padding

    # --- Rectangle Comparison ---

    # Threshold for vertical overlap comparison
    attr_accessor :vertical_comparison_threshold

    def initialize
      # Ruling detection
      @orientation_tolerance = 1.0
      @intersection_tolerance = 1.0
      @ruling_thickness_threshold = 8.0

      # Text element merging
      @word_gap_multiplier = 0.5
      @line_gap_multiplier = 0.5

      # Cell detection
      @min_cells = 4
      @min_table_dimension = 10.0
      @cell_tolerance = 2.0

      # Table detection
      @min_rows = 2
      @overlap_threshold = 0.9
      @tabular_ratio_threshold = 0.65
      @edge_clustering_tolerance = 8.0
      @detection_padding = 2.0

      # Rectangle comparison
      @vertical_comparison_threshold = 0.4
    end

    # Create a copy with overrides
    # @param overrides [Hash] values to override
    # @return [Configuration]
    def with(**overrides)
      dup.tap do |config|
        overrides.each { |key, value| config.send("#{key}=", value) }
      end
    end
  end

  # Default configuration instance
  @default_configuration = Configuration.new

  class << self
    # Get the default configuration
    # @return [Configuration]
    def configuration
      @default_configuration
    end

    # Set the default configuration
    # @param config [Configuration]
    def configuration=(config)
      @default_configuration = config
    end

    # Configure with a block
    # @yield [Configuration]
    def configure
      yield configuration
    end
  end
end
