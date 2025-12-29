# frozen_string_literal: true

module Tabula
  # Cohen-Sutherland line clipping algorithm.
  # Clips a line segment to a rectangular region.
  module CohenSutherlandClipping
    # Region codes for Cohen-Sutherland algorithm
    INSIDE = 0b0000
    LEFT   = 0b0001
    RIGHT  = 0b0010
    BOTTOM = 0b0100
    TOP    = 0b1000

    class << self
      # Clip a ruling to a rectangular region
      # @param ruling [Ruling] the line segment to clip
      # @param rect [Rectangle] the clipping region
      # @return [Ruling, nil] clipped ruling, or nil if entirely outside
      def clip(ruling, rect)
        x1 = ruling.x1
        y1 = ruling.y1
        x2 = ruling.x2
        y2 = ruling.y2

        min_x = rect.left
        max_x = rect.right
        min_y = rect.top
        max_y = rect.bottom

        code1 = compute_code(x1, y1, min_x, max_x, min_y, max_y)
        code2 = compute_code(x2, y2, min_x, max_x, min_y, max_y)

        loop do
          # Both endpoints inside - trivially accept
          return Ruling.new(x1, y1, x2, y2) if (code1 | code2).zero?

          # Both endpoints share an outside region - trivially reject
          return nil if (code1 & code2).nonzero?

          # At least one endpoint is outside, select it
          code_out = code1.nonzero? ? code1 : code2

          # Find intersection point
          x, y = find_intersection(x1, y1, x2, y2, code_out, min_x, max_x, min_y, max_y)

          # Replace the outside point
          if code_out == code1
            x1 = x
            y1 = y
            code1 = compute_code(x1, y1, min_x, max_x, min_y, max_y)
          else
            x2 = x
            y2 = y
            code2 = compute_code(x2, y2, min_x, max_x, min_y, max_y)
          end
        end
      end

      private

      def compute_code(x, y, min_x, max_x, min_y, max_y)
        code = INSIDE
        code |= LEFT if x < min_x
        code |= RIGHT if x > max_x
        code |= TOP if y < min_y
        code |= BOTTOM if y > max_y
        code
      end

      def find_intersection(x1, y1, x2, y2, code_out, min_x, max_x, min_y, max_y)
        x = 0.0
        y = 0.0
        dx = x2 - x1
        dy = y2 - y1

        if (code_out & BOTTOM).nonzero?
          x = x1 + (dx * (max_y - y1) / dy)
          y = max_y
        elsif (code_out & TOP).nonzero?
          x = x1 + (dx * (min_y - y1) / dy)
          y = min_y
        elsif (code_out & RIGHT).nonzero?
          y = y1 + (dy * (max_x - x1) / dx)
          x = max_x
        elsif (code_out & LEFT).nonzero?
          y = y1 + (dy * (min_x - x1) / dx)
          x = min_x
        end

        [x, y]
      end
    end
  end
end
