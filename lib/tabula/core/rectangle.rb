# frozen_string_literal: true

module Tabula
  # Represents a rectangle with position and dimensions.
  # Coordinates use PDF coordinate system (origin at bottom-left).
  class Rectangle
    # Threshold for vertical overlap comparison (40% overlap)
    VERTICAL_COMPARISON_THRESHOLD = 0.4

    attr_accessor :top, :left, :width, :height

    def initialize(top, left, width, height)
      @top = top.to_f
      @left = left.to_f
      @width = width.to_f
      @height = height.to_f
    end

    # Create rectangle from bounds [top, left, bottom, right]
    def self.from_bounds(top, left, bottom, right)
      new(top, left, right - left, bottom - top)
    end

    # Create rectangle from two points
    def self.from_points(p1, p2)
      top = [p1.y, p2.y].min
      left = [p1.x, p2.x].min
      bottom = [p1.y, p2.y].max
      right = [p1.x, p2.x].max
      from_bounds(top, left, bottom, right)
    end

    # Compute bounding box of multiple rectangles
    def self.bounding_box_of(rectangles)
      return nil if rectangles.empty?

      top = rectangles.map(&:top).min
      left = rectangles.map(&:left).min
      bottom = rectangles.map(&:bottom).max
      right = rectangles.map(&:right).max

      from_bounds(top, left, bottom, right)
    end

    def bottom
      top + height
    end

    def bottom=(value)
      @height = value - top
    end

    def right
      left + width
    end

    def right=(value)
      @width = value - left
    end

    def x
      left
    end

    def x=(value)
      self.left = value
    end

    def y
      top
    end

    def y=(value)
      self.top = value
    end

    def area
      width * height
    end

    def center
      Point.new(left + width / 2.0, top + height / 2.0)
    end

    def bounds
      [top, left, bottom, right]
    end

    def points
      [
        Point.new(left, top),
        Point.new(right, top),
        Point.new(right, bottom),
        Point.new(left, bottom)
      ]
    end

    # Calculate vertical overlap with another rectangle
    def vertical_overlap(other)
      [0, [bottom, other.bottom].min - [top, other.top].max].max
    end

    # Calculate horizontal overlap with another rectangle
    def horizontal_overlap(other)
      [0, [right, other.right].min - [left, other.left].max].max
    end

    # Check if rectangles overlap vertically
    def vertically_overlaps?(other, threshold = VERTICAL_COMPARISON_THRESHOLD)
      overlap = vertical_overlap(other)
      min_height = [height, other.height].min
      return false if min_height.zero?

      (overlap / min_height) >= threshold
    end

    # Check if rectangles overlap horizontally
    def horizontally_overlaps?(other, threshold = 0.0)
      overlap = horizontal_overlap(other)
      min_width = [width, other.width].min
      return true if min_width.zero? && overlap.zero?
      return false if min_width.zero?

      (overlap / min_width) > threshold
    end

    # Calculate overlap ratio (intersection area / union area)
    def overlap_ratio(other)
      intersection_area = vertical_overlap(other) * horizontal_overlap(other)
      return 0.0 if intersection_area.zero?

      union_area = area + other.area - intersection_area
      return 0.0 if union_area.zero?

      intersection_area / union_area
    end

    # Check if this rectangle contains a point
    def contains_point?(point)
      point.x >= left && point.x <= right && point.y >= top && point.y <= bottom
    end

    # Check if this rectangle fully contains another
    def contains?(other)
      left <= other.left && right >= other.right && top <= other.top && bottom >= other.bottom
    end

    # Check if this rectangle intersects another
    def intersects?(other)
      !(other.left > right || other.right < left || other.top > bottom || other.bottom < top)
    end

    # Merge this rectangle with another, returning the bounding box
    def merge(other)
      Rectangle.from_bounds(
        [top, other.top].min,
        [left, other.left].min,
        [bottom, other.bottom].max,
        [right, other.right].max
      )
    end

    # Merge in place
    def merge!(other)
      merged = merge(other)
      @top = merged.top
      @left = merged.left
      @width = merged.width
      @height = merged.height
      self
    end

    # Return intersection rectangle, or nil if no intersection
    def intersection(other)
      return nil unless intersects?(other)

      Rectangle.from_bounds(
        [top, other.top].max,
        [left, other.left].max,
        [bottom, other.bottom].min,
        [right, other.right].min
      )
    end

    def ==(other)
      return false unless other.is_a?(Rectangle)

      top == other.top && left == other.left && width == other.width && height == other.height
    end
    alias eql? ==

    def hash
      [top, left, width, height].hash
    end

    def dup
      Rectangle.new(top, left, width, height)
    end

    def to_s
      "Rectangle[top=#{top}, left=#{left}, width=#{width}, height=#{height}]"
    end

    def inspect
      to_s
    end

    # Comparator for sorting by position (top to bottom, left to right)
    def <=>(other)
      result = top <=> other.top
      return result unless result.zero?

      left <=> other.left
    end

    include Comparable
  end
end
