# frozen_string_literal: true

module Tabula
  module Detectors
    # Detects table areas using ruling line analysis.
    # Suitable for PDFs with clear table borders.
    class SpreadsheetDetection < DetectionAlgorithm
      # Minimum cells for a valid table
      MIN_CELLS = 4

      # Minimum table dimension (in points)
      MIN_DIMENSION = 10

      def initialize(**options)
        super
      end

      # Detect table areas on a page
      # @param page [Page] page to detect tables on
      # @return [Array<Rectangle>] detected table areas
      def detect(page)
        horizontal = page.horizontal_rulings
        vertical = page.vertical_rulings

        return [] if horizontal.empty? || vertical.empty?

        # Find cells from ruling intersections
        cells = find_cells(horizontal, vertical)
        return [] if cells.size < MIN_CELLS

        # Group cells into table regions
        regions = find_table_regions(cells)

        # Filter valid regions
        regions.select { |r| valid_table_region?(r) }
      end

      private

      def find_cells(horizontal_rulings, vertical_rulings)
        # Use the same logic as SpreadsheetExtractionAlgorithm
        cells = []

        # Find intersection points
        intersections = build_intersection_map(horizontal_rulings, vertical_rulings)
        return cells if intersections.empty?

        # Get unique x and y positions
        x_positions = intersections.keys.map { |x, _| x }.uniq.sort
        y_positions = intersections.keys.map { |_, y| y }.uniq.sort

        # Find cells by checking for rectangular intersections
        y_positions.each_cons(2) do |top, bottom|
          x_positions.each_cons(2) do |left, right|
            if valid_cell?(left, right, top, bottom, intersections)
              cells << Rectangle.new(top, left, right - left, bottom - top)
            end
          end
        end

        cells
      end

      def build_intersection_map(horizontal_rulings, vertical_rulings)
        intersections = {}

        horizontal_rulings.each do |h|
          vertical_rulings.each do |v|
            next unless h.intersects?(v)

            point = h.intersection_point(v)
            next unless point

            key = [point.x.round(1), point.y.round(1)]
            intersections[key] = true
          end
        end

        intersections
      end

      def valid_cell?(left, right, top, bottom, intersections)
        tolerance = 2.0

        corners = [
          [left, top],
          [right, top],
          [left, bottom],
          [right, bottom]
        ]

        corners.all? do |x, y|
          intersections.keys.any? do |ix, iy|
            (x - ix).abs <= tolerance && (y - iy).abs <= tolerance
          end
        end
      end

      def find_table_regions(cells)
        return [] if cells.empty?

        regions = []
        remaining = cells.dup

        until remaining.empty?
          seed = remaining.shift
          region = [seed]

          loop do
            adjacent = remaining.select { |c| adjacent_to_region?(c, region) }
            break if adjacent.empty?

            region.concat(adjacent)
            remaining -= adjacent
          end

          regions << Rectangle.bounding_box_of(region)
        end

        regions
      end

      def adjacent_to_region?(cell, region)
        region.any? { |r| cells_adjacent?(r, cell) }
      end

      def cells_adjacent?(c1, c2)
        tolerance = 2.0

        # Horizontal adjacency
        h_adjacent = (c1.right - c2.left).abs <= tolerance || (c2.right - c1.left).abs <= tolerance
        v_overlap = c1.vertically_overlaps?(c2, 0.5)

        # Vertical adjacency
        v_adjacent = (c1.bottom - c2.top).abs <= tolerance || (c2.bottom - c1.top).abs <= tolerance
        h_overlap = c1.horizontally_overlaps?(c2, 0.5)

        (h_adjacent && v_overlap) || (v_adjacent && h_overlap)
      end

      def valid_table_region?(region)
        region.width >= MIN_DIMENSION && region.height >= MIN_DIMENSION
      end
    end
  end
end
