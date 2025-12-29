# frozen_string_literal: true

module Tabula
  # Spatial index for efficient rectangle queries.
  # Uses a simple grid-based approach for O(1) average lookup.
  class SpatialIndex
    attr_reader :rectangles

    # @param cell_size [Float] size of grid cells (default 50)
    def initialize(cell_size: 50.0)
      @cell_size = cell_size
      @grid = Hash.new { |h, k| h[k] = [] }
      @rectangles = []
    end

    # Add a rectangle to the index
    # @param rectangle [Rectangle] rectangle to add
    def add(rectangle)
      @rectangles << rectangle
      cells_for(rectangle).each do |cell|
        @grid[cell] << rectangle
      end
      self
    end

    # Add multiple rectangles
    # @param rectangles [Array<Rectangle>] rectangles to add
    def add_all(rectangles)
      rectangles.each { |r| add(r) }
      self
    end

    # Find all rectangles that intersect with the query rectangle
    # @param query [Rectangle] query rectangle
    # @return [Array<Rectangle>] intersecting rectangles
    def intersects(query)
      candidates = candidate_set(query)
      candidates.select { |r| r.intersects?(query) }
    end

    # Find all rectangles that are fully contained within the query rectangle
    # @param query [Rectangle] query rectangle
    # @return [Array<Rectangle>] contained rectangles
    def contains(query)
      candidates = candidate_set(query)
      candidates.select { |r| query.contains?(r) }
    end

    # Find all rectangles that contain the query point
    # @param point [Point] query point
    # @return [Array<Rectangle>] rectangles containing the point
    def at_point(point)
      cell = cell_for_point(point)
      @grid[cell].select { |r| r.contains_point?(point) }
    end

    # Find rectangles within a given distance of the query rectangle
    # @param query [Rectangle] query rectangle
    # @param distance [Float] maximum distance
    # @return [Array<Rectangle>] nearby rectangles
    def nearby(query, distance)
      expanded = Rectangle.from_bounds(
        query.top - distance,
        query.left - distance,
        query.bottom + distance,
        query.right + distance
      )
      intersects(expanded)
    end

    # Compute bounding box of all indexed rectangles
    # @return [Rectangle, nil] bounding box or nil if empty
    def bounds
      Rectangle.bounding_box_of(@rectangles)
    end

    # Number of indexed rectangles
    def size
      @rectangles.size
    end

    def empty?
      @rectangles.empty?
    end

    # Clear all indexed rectangles
    def clear
      @grid.clear
      @rectangles.clear
      self
    end

    private

    def cell_for_point(point)
      col = (point.x / @cell_size).floor
      row = (point.y / @cell_size).floor
      [col, row]
    end

    def cells_for(rectangle)
      min_col = (rectangle.left / @cell_size).floor
      max_col = (rectangle.right / @cell_size).floor
      min_row = (rectangle.top / @cell_size).floor
      max_row = (rectangle.bottom / @cell_size).floor

      cells = []
      (min_col..max_col).each do |col|
        (min_row..max_row).each do |row|
          cells << [col, row]
        end
      end
      cells
    end

    def candidate_set(query)
      cells_for(query).flat_map { |cell| @grid[cell] }.uniq
    end
  end
end
