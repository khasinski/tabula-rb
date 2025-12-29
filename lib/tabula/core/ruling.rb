# frozen_string_literal: true

module Tabula
  # Represents a ruling line (horizontal or vertical line segment) in a PDF.
  # Used for detecting table cell boundaries in lattice-mode extraction.
  class Ruling
    # Tolerance for considering lines as horizontal/vertical
    ORIENTATION_TOLERANCE = 1.0

    # Tolerance for near-intersection detection
    INTERSECTION_TOLERANCE = 1.0

    attr_accessor :x1, :y1, :x2, :y2

    def initialize(x1, y1, x2, y2)
      @x1 = x1.to_f
      @y1 = y1.to_f
      @x2 = x2.to_f
      @y2 = y2.to_f
      normalize!
    end

    # Create from two points
    def self.from_points(p1, p2)
      new(p1.x, p1.y, p2.x, p2.y)
    end

    # Create from top, left, width, height (like Rectangle)
    def self.from_bounds(top, left, width, height)
      new(left, top, left + width, top + height)
    end

    # Normalize almost-horizontal and almost-vertical lines
    def normalize!
      if horizontal?
        avg_y = (y1 + y2) / 2.0
        @y1 = avg_y
        @y2 = avg_y
        # Ensure x1 < x2
        @x1, @x2 = @x2, @x1 if x1 > x2
      elsif vertical?
        avg_x = (x1 + x2) / 2.0
        @x1 = avg_x
        @x2 = avg_x
        # Ensure y1 < y2
        @y1, @y2 = @y2, @y1 if y1 > y2
      end
      self
    end

    def horizontal?
      (y2 - y1).abs <= ORIENTATION_TOLERANCE
    end

    def vertical?
      (x2 - x1).abs <= ORIENTATION_TOLERANCE
    end

    def oblique?
      !horizontal? && !vertical?
    end

    # Position perpendicular to the line (y for horizontal, x for vertical)
    def position
      horizontal? ? y1 : x1
    end

    def position=(value)
      if horizontal?
        @y1 = value
        @y2 = value
      else
        @x1 = value
        @x2 = value
      end
    end

    # Start point along the line direction
    def start
      horizontal? ? x1 : y1
    end

    # End point along the line direction
    def end
      horizontal? ? x2 : y2
    end

    def length
      Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
    end

    def top
      [y1, y2].min
    end

    def bottom
      [y1, y2].max
    end

    def left
      [x1, x2].min
    end

    def right
      [x1, x2].max
    end

    # Get start and end points as Point objects
    def p1
      Point.new(x1, y1)
    end

    def p2
      Point.new(x2, y2)
    end

    # Calculate angle in degrees (0 = horizontal, 90 = vertical)
    def angle
      Math.atan2(y2 - y1, x2 - x1) * 180.0 / Math::PI
    end

    # Find intersection point with another ruling (only for orthogonal lines)
    def intersection_point(other)
      return nil if horizontal? == other.horizontal?
      return nil if oblique? || other.oblique?

      if horizontal?
        Point.new(other.x1, y1)
      else
        Point.new(x1, other.y1)
      end
    end

    # Check if this ruling intersects another (with tolerance)
    def intersects?(other, tolerance = INTERSECTION_TOLERANCE)
      point = intersection_point(other)
      return false unless point

      # Check if intersection point lies within both line segments
      if horizontal?
        x_in_self = point.x >= (left - tolerance) && point.x <= (right + tolerance)
        y_in_other = point.y >= (other.top - tolerance) && point.y <= (other.bottom + tolerance)
        x_in_self && y_in_other
      else
        y_in_self = point.y >= (top - tolerance) && point.y <= (bottom + tolerance)
        x_in_other = point.x >= (other.left - tolerance) && point.x <= (other.right + tolerance)
        y_in_self && x_in_other
      end
    end

    # Check if lines nearly intersect (for cell detection)
    def nearly_intersects?(other, tolerance = INTERSECTION_TOLERANCE)
      intersects?(other, tolerance)
    end

    # Expand the ruling by extending its endpoints
    def expand(amount)
      if horizontal?
        Ruling.new(x1 - amount, y1, x2 + amount, y2)
      elsif vertical?
        Ruling.new(x1, y1 - amount, x2, y2 + amount)
      else
        # For oblique lines, expand in both directions
        dx = (x2 - x1) / length * amount
        dy = (y2 - y1) / length * amount
        Ruling.new(x1 - dx, y1 - dy, x2 + dx, y2 + dy)
      end
    end

    # Clip ruling to a rectangular area
    def clip_to(rect)
      CohenSutherlandClipping.clip(self, rect)
    end

    # Check if this ruling overlaps with another (for collapsing)
    def colinear_with?(other, tolerance = 1.0)
      return false unless horizontal? == other.horizontal?

      if horizontal?
        (y1 - other.y1).abs < tolerance
      else
        (x1 - other.x1).abs < tolerance
      end
    end

    def ==(other)
      return false unless other.is_a?(Ruling)

      x1 == other.x1 && y1 == other.y1 && x2 == other.x2 && y2 == other.y2
    end
    alias eql? ==

    def hash
      [x1, y1, x2, y2].hash
    end

    def dup
      Ruling.new(x1, y1, x2, y2)
    end

    def to_s
      orientation = horizontal? ? "H" : (vertical? ? "V" : "O")
      "Ruling[#{orientation}](#{x1}, #{y1}) -> (#{x2}, #{y2})"
    end

    def inspect
      to_s
    end

    class << self
      # Find all intersection points between horizontal and vertical rulings
      # Uses sweep line algorithm for O(n log n) performance
      def find_intersections(horizontal_rulings, vertical_rulings)
        intersections = {}

        horizontal_rulings.each do |h|
          vertical_rulings.each do |v|
            next unless h.intersects?(v)

            point = h.intersection_point(v)
            next unless point

            # Round to avoid floating point issues
            key = [point.x.round(2), point.y.round(2)]
            intersections[key] ||= point
          end
        end

        intersections.values
      end

      # Collapse colinear rulings that are close together
      def collapse_oriented_rulings(rulings, tolerance = 1.0)
        return [] if rulings.empty?

        # Separate horizontal and vertical
        horizontal = rulings.select(&:horizontal?).sort_by(&:y1)
        vertical = rulings.select(&:vertical?).sort_by(&:x1)

        collapsed = []
        collapsed.concat(collapse_group(horizontal, tolerance))
        collapsed.concat(collapse_group(vertical, tolerance))
        collapsed
      end

      # Crop rulings to a rectangular area
      def crop_to_area(rulings, rect)
        rulings.filter_map { |r| r.clip_to(rect) }
      end

      private

      def collapse_group(rulings, tolerance)
        return [] if rulings.empty?

        groups = []
        current_group = [rulings.first]

        rulings[1..].each do |ruling|
          if current_group.last.colinear_with?(ruling, tolerance)
            current_group << ruling
          else
            groups << current_group
            current_group = [ruling]
          end
        end
        groups << current_group

        # Merge each group into a single ruling
        groups.map do |group|
          if group.first.horizontal?
            y = group.map(&:y1).sum / group.size
            min_x = group.map(&:left).min
            max_x = group.map(&:right).max
            Ruling.new(min_x, y, max_x, y)
          else
            x = group.map(&:x1).sum / group.size
            min_y = group.map(&:top).min
            max_y = group.map(&:bottom).max
            Ruling.new(x, min_y, x, max_y)
          end
        end
      end
    end
  end
end
