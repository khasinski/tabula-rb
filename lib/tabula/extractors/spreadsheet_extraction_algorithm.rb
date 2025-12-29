# frozen_string_literal: true

module Tabula
  module Extractors
    # Lattice-mode extraction algorithm.
    # Extracts tables by analyzing ruling lines (cell borders) in the PDF.
    class Spreadsheet < ExtractionAlgorithm
      # Minimum cells required for a valid table
      MIN_CELLS = 4

      # Magic heuristic for determining tabular content
      TABULAR_RATIO_THRESHOLD = 0.65

      def initialize(**options)
        super
      end

      # Extract tables from a page
      # @param page [Page] page to extract from
      # @return [Array<Table>]
      def extract(page)
        horizontal = page.horizontal_rulings
        vertical = page.vertical_rulings

        return [] if horizontal.empty? || vertical.empty?

        # Find cells from ruling intersections
        cells = find_cells(horizontal, vertical)
        return [] if cells.size < MIN_CELLS

        # Find spreadsheet regions from cells
        spreadsheet_areas = find_spreadsheet_areas(cells)
        return [] if spreadsheet_areas.empty?

        # Extract tables from each region
        tables = spreadsheet_areas.map do |area|
          extract_table_from_area(page, area, horizontal, vertical)
        end

        tables.reject(&:empty?)
      end

      # Check if a page contains tabular content
      # @param page [Page] page to check
      # @return [Boolean]
      def self.tabular?(page)
        extractor = new
        tables = extractor.extract(page)
        return false if tables.empty?

        # Check if tables have reasonable structure
        tables.any? do |table|
          ratio = table.row_count.to_f / table.col_count
          ratio >= TABULAR_RATIO_THRESHOLD && ratio <= (1.0 / TABULAR_RATIO_THRESHOLD)
        end
      end

      private

      def find_cells(horizontal_rulings, vertical_rulings)
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
            # Check if all four corners have intersections
            if valid_cell?(left, right, top, bottom, intersections)
              cells << Cell.new(top, left, right - left, bottom - top)
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

            # Round to avoid floating point issues
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
          # Check with tolerance
          intersections.keys.any? do |ix, iy|
            (x - ix).abs <= tolerance && (y - iy).abs <= tolerance
          end
        end
      end

      def find_spreadsheet_areas(cells)
        return [] if cells.empty?

        # Group adjacent cells into regions
        regions = []
        remaining = cells.dup

        until remaining.empty?
          seed = remaining.shift
          region = [seed]

          loop do
            adjacent = remaining.select { |c| adjacent?(region, c) }
            break if adjacent.empty?

            region.concat(adjacent)
            remaining -= adjacent
          end

          regions << Rectangle.bounding_box_of(region)
        end

        # Filter out small regions
        regions.select { |r| r.area > 0 }
      end

      def adjacent?(region, cell)
        region.any? { |r| cells_adjacent?(r, cell) }
      end

      def cells_adjacent?(c1, c2)
        # Cells are adjacent if they share an edge
        tolerance = 2.0

        # Horizontal adjacency (share vertical edge)
        horizontal = (c1.right - c2.left).abs <= tolerance || (c2.right - c1.left).abs <= tolerance
        vertical_overlap = c1.vertically_overlaps?(c2, 0.5)

        # Vertical adjacency (share horizontal edge)
        vertical = (c1.bottom - c2.top).abs <= tolerance || (c2.bottom - c1.top).abs <= tolerance
        horizontal_overlap = c1.horizontally_overlaps?(c2, 0.5)

        (horizontal && vertical_overlap) || (vertical && horizontal_overlap)
      end

      def extract_table_from_area(page, area, horizontal_rulings, vertical_rulings)
        # Get rulings within the area
        h_rulings = horizontal_rulings.select { |r| ruling_in_area?(r, area) }
        v_rulings = vertical_rulings.select { |r| ruling_in_area?(r, area) }

        # Get unique positions for grid
        y_positions = h_rulings.map(&:y1).uniq.sort
        x_positions = v_rulings.map(&:x1).uniq.sort

        return Table.new if y_positions.size < 2 || x_positions.size < 2

        # Build table
        table = Table::WithRulingLines.new(
          horizontal_rulings: h_rulings,
          vertical_rulings: v_rulings,
          extraction_method: name,
          page_number: page.page_number
        )

        # Create cells and populate with text
        y_positions.each_cons(2).with_index do |(top, bottom), row_idx|
          x_positions.each_cons(2).with_index do |(left, right), col_idx|
            cell = Cell.new(top, left, right - left, bottom - top)

            # Find text elements in this cell
            cell_area = Rectangle.from_bounds(top, left, bottom, right)
            text_elements = page.get_text(cell_area)
            cell.add_all(text_elements)

            table.add(row_idx, col_idx, cell)
          end
        end

        table
      end

      def ruling_in_area?(ruling, area)
        ruling_rect = Rectangle.from_bounds(ruling.top, ruling.left, ruling.bottom, ruling.right)
        area.intersects?(ruling_rect)
      end
    end
  end
end
