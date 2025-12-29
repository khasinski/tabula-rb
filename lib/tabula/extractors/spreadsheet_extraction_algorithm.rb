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

        # Find spreadsheet regions from cells and get cells per region
        cell_groups = find_spreadsheet_areas_with_cells(cells)
        return [] if cell_groups.empty?

        # Extract tables from each region using the found cells
        tables = cell_groups.map do |region_cells|
          extract_table_from_cells(page, region_cells, horizontal, vertical)
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
          ratio.between?(TABULAR_RATIO_THRESHOLD, 1.0 / TABULAR_RATIO_THRESHOLD)
        end
      end

      private

      def find_cells(horizontal_rulings, vertical_rulings)
        cells = []
        tolerance = Tabula.configuration.cell_tolerance

        # Find intersection points
        intersections = build_intersection_map(horizontal_rulings, vertical_rulings)
        return cells if intersections.empty?

        # Get unique y positions from horizontal rulings (row boundaries)
        y_positions = horizontal_rulings.map { |r| r.y1.round(1) }.uniq.sort

        return cells if y_positions.size < 2

        # Process each row individually to handle spanning cells
        y_positions.each_cons(2) do |top, bottom|
          # Find vertical rulings that span this row (intersect with row's Y range)
          row_verticals = vertical_rulings.select do |v|
            v.y1 <= top + tolerance && v.y2 >= bottom - tolerance
          end

          # Get unique X positions from vertical rulings only
          x_positions = row_verticals.map { |v| v.x1.round(1) }.uniq.sort

          next if x_positions.size < 2

          # Create cells for this row
          x_positions.each_cons(2) do |left, right|
            # Verify this cell has valid edges
            if valid_cell_by_edges?(left, right, top, bottom, horizontal_rulings, vertical_rulings, tolerance)
              cells << Cell.new(top, left, right - left, bottom - top)
            # Also accept cells with corner validation
            elsif valid_cell_by_corners?(left, right, top, bottom, intersections, tolerance)
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

      def valid_cell_by_corners?(left, right, top, bottom, intersections, tolerance)
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

      # Check if there are rulings that form the edges of a potential cell
      def valid_cell_by_edges?(left, right, top, bottom, horizontal_rulings, vertical_rulings, tolerance)
        # Check for top edge (horizontal ruling at top that covers left to right)
        has_top = horizontal_rulings.any? do |h|
          (h.y1 - top).abs <= tolerance &&
            h.x1 <= left + tolerance &&
            h.x2 >= right - tolerance
        end

        # Check for bottom edge
        has_bottom = horizontal_rulings.any? do |h|
          (h.y1 - bottom).abs <= tolerance &&
            h.x1 <= left + tolerance &&
            h.x2 >= right - tolerance
        end

        # Check for left edge (vertical ruling at left that covers top to bottom)
        has_left = vertical_rulings.any? do |v|
          (v.x1 - left).abs <= tolerance &&
            v.y1 <= top + tolerance &&
            v.y2 >= bottom - tolerance
        end

        # Check for right edge
        has_right = vertical_rulings.any? do |v|
          (v.x1 - right).abs <= tolerance &&
            v.y1 <= top + tolerance &&
            v.y2 >= bottom - tolerance
        end

        has_top && has_bottom && has_left && has_right
      end

      def find_spreadsheet_areas(cells)
        find_spreadsheet_areas_with_cells(cells).map do |region_cells|
          Rectangle.bounding_box_of(region_cells)
        end
      end

      def find_spreadsheet_areas_with_cells(cells)
        return [] if cells.empty?

        # Group adjacent cells into regions
        cell_groups = []
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

          # Filter out small regions
          bbox = Rectangle.bounding_box_of(region)
          cell_groups << region if bbox.area.positive?
        end

        cell_groups
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

      def extract_table_from_cells(page, cells, horizontal_rulings, vertical_rulings)
        return Table.new if cells.empty?

        # Get area bounds from cells
        area = Rectangle.bounding_box_of(cells)

        # Get rulings within the area
        h_rulings = horizontal_rulings.select { |r| ruling_in_area?(r, area) }
        v_rulings = vertical_rulings.select { |r| ruling_in_area?(r, area) }

        # Build table
        table = Table::WithRulingLines.new(
          horizontal_rulings: h_rulings,
          vertical_rulings: v_rulings,
          extraction_method: name,
          page_number: page.page_number
        )

        # Organize cells into grid positions
        # Get unique y positions (rows) and sort cells by position
        y_positions = cells.map { |c| c.top.round(1) }.uniq.sort
        y_to_row = y_positions.each_with_index.to_h

        cells.each do |cell|
          row_idx = y_to_row[cell.top.round(1)]
          next unless row_idx

          # Find column index based on x position within this row
          row_cells = cells.select { |c| (c.top - cell.top).abs < 2 }.sort_by(&:left)
          col_idx = row_cells.index(cell) || 0

          # Populate cell with text elements
          cell_area = Rectangle.from_bounds(cell.top, cell.left, cell.bottom, cell.right)
          text_elements = page.get_text(cell_area)
          cell.add_all(text_elements)

          table.add(row_idx, col_idx, cell)
        end

        table
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
