# frozen_string_literal: true

module Tabula
  module Detectors
    # Nurminen's table detection algorithm.
    # Based on Anssi Nurminen's master's thesis approach.
    # Detects tables using text alignment and edge analysis.
    class Nurminen < DetectionAlgorithm
      # Text edge types
      EDGE_LEFT = 0
      EDGE_MID = 1
      EDGE_RIGHT = 2

      # Minimum rows for a valid table
      MIN_ROWS = 2

      # Overlap threshold for duplicate detection
      OVERLAP_THRESHOLD = 0.9

      def initialize(**options)
        super
      end

      # Detect table areas on a page
      # @param page [Page] page to detect tables on
      # @return [Array<Rectangle>] detected table areas
      def detect(page)
        tables = []

        # First, try ruling-based detection
        ruling_tables = detect_from_rulings(page)
        tables.concat(ruling_tables)

        # Then, try text-based detection
        text_tables = detect_from_text(page)

        # Merge results, removing duplicates
        text_tables.each do |text_table|
          unless overlaps_existing?(text_table, tables)
            tables << text_table
          end
        end

        tables
      end

      private

      def detect_from_rulings(page)
        SpreadsheetDetection.detect(page)
      end

      def detect_from_text(page)
        lines = page.text_lines
        return [] if lines.size < MIN_ROWS

        # Find text edges
        edges = find_text_edges(lines)
        return [] if edges.empty?

        # Find relevant edges (most common alignment)
        relevant = find_relevant_edges(edges)
        return [] if relevant.empty?

        # Detect tables from edge patterns
        detect_tables_from_edges(lines, relevant, page)
      end

      def find_text_edges(lines)
        edges = { EDGE_LEFT => [], EDGE_MID => [], EDGE_RIGHT => [] }

        lines.each do |line|
          line.sorted_chunks.each do |chunk|
            # Left edge
            edges[EDGE_LEFT] << TextEdge.new(chunk.left, line.top, line.bottom, EDGE_LEFT)

            # Center edge
            center = chunk.left + chunk.width / 2.0
            edges[EDGE_MID] << TextEdge.new(center, line.top, line.bottom, EDGE_MID)

            # Right edge
            edges[EDGE_RIGHT] << TextEdge.new(chunk.right, line.top, line.bottom, EDGE_RIGHT)
          end
        end

        edges
      end

      def find_relevant_edges(edges)
        # Cluster edges by x position
        all_edges = edges.values.flatten
        return [] if all_edges.empty?

        clustered = cluster_edges(all_edges)
        return [] if clustered.empty?

        # Find edges that appear in multiple rows
        min_occurrences = [2, (all_edges.size * 0.1).ceil].max
        clustered.select { |_, count| count >= min_occurrences }.keys
      end

      def cluster_edges(edges, tolerance: 8.0)
        return {} if edges.empty?

        sorted = edges.sort_by(&:x)
        clusters = {}
        current_cluster = [sorted.first]

        sorted[1..].each do |edge|
          if (edge.x - current_cluster.last.x).abs <= tolerance
            current_cluster << edge
          else
            avg_x = current_cluster.sum(&:x) / current_cluster.size
            clusters[avg_x] = current_cluster.size
            current_cluster = [edge]
          end
        end

        unless current_cluster.empty?
          avg_x = current_cluster.sum(&:x) / current_cluster.size
          clusters[avg_x] = current_cluster.size
        end

        clusters
      end

      def detect_tables_from_edges(lines, edge_positions, page)
        return [] if edge_positions.size < 2

        tables = []

        # Look for consistent patterns across consecutive lines
        table_start = nil
        table_lines = []

        lines.each_with_index do |line, idx|
          line_edges = extract_line_edges(line)
          aligned = edges_aligned_with_columns?(line_edges, edge_positions)

          if aligned
            table_start ||= idx
            table_lines << line
          elsif table_lines.size >= MIN_ROWS
            # End of table
            table = create_table_bounds(table_lines, page)
            tables << table if table
            table_start = nil
            table_lines = []
          else
            table_start = nil
            table_lines = []
          end
        end

        # Handle table at end of page
        if table_lines.size >= MIN_ROWS
          table = create_table_bounds(table_lines, page)
          tables << table if table
        end

        tables
      end

      def extract_line_edges(line)
        edges = []
        line.sorted_chunks.each do |chunk|
          edges << chunk.left
          edges << chunk.right
        end
        edges
      end

      def edges_aligned_with_columns?(line_edges, column_positions, tolerance: 10.0)
        return false if line_edges.empty?

        # Check if at least half of the line edges align with column positions
        aligned_count = line_edges.count do |edge|
          column_positions.any? { |col| (edge - col).abs <= tolerance }
        end

        aligned_count >= (line_edges.size * 0.3)
      end

      def create_table_bounds(lines, page)
        return nil if lines.empty?

        bounds = Rectangle.bounding_box_of(lines)
        return nil unless bounds

        # Expand slightly to include full cell boundaries
        padding = 2.0
        Rectangle.from_bounds(
          [bounds.top - padding, 0].max,
          [bounds.left - padding, 0].max,
          [bounds.bottom + padding, page.height].min,
          [bounds.right + padding, page.width].min
        )
      end

      def overlaps_existing?(table, existing_tables)
        existing_tables.any? { |t| t.overlap_ratio(table) >= OVERLAP_THRESHOLD }
      end

      # Helper class for text edges
      class TextEdge
        attr_reader :x, :top, :bottom, :type

        def initialize(x, top, bottom, type)
          @x = x
          @top = top
          @bottom = bottom
          @type = type
        end
      end
    end
  end
end
