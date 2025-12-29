# frozen_string_literal: true

module Tabula
  # Represents a 2D point with x and y coordinates
  class Point
    attr_accessor :x, :y

    def initialize(x, y)
      @x = x.to_f
      @y = y.to_f
    end

    def to_a
      [x, y]
    end

    def ==(other)
      return false unless other.is_a?(Point)

      x == other.x && y == other.y
    end
    alias eql? ==

    def hash
      [x, y].hash
    end

    def distance_to(other)
      Math.sqrt((x - other.x)**2 + (y - other.y)**2)
    end

    def distance_squared_to(other)
      (x - other.x)**2 + (y - other.y)**2
    end

    def +(other)
      Point.new(x + other.x, y + other.y)
    end

    def -(other)
      Point.new(x - other.x, y - other.y)
    end

    def *(scalar)
      Point.new(x * scalar, y * scalar)
    end

    def /(scalar)
      Point.new(x / scalar, y / scalar)
    end

    def to_s
      "Point(#{x}, #{y})"
    end

    def inspect
      to_s
    end
  end
end
