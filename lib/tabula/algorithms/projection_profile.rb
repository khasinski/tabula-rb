# frozen_string_literal: true

module Tabula
  # Projection profile analysis for detecting table structure.
  # Computes histograms of text element positions to find gaps.
  class ProjectionProfile
    attr_reader :min_value, :max_value, :bins

    # @param elements [Array<Rectangle>] elements to analyze
    # @param orientation [Symbol] :horizontal or :vertical
    # @param bin_size [Float] size of histogram bins
    def initialize(elements, orientation:, bin_size: 1.0)
      @orientation = orientation
      @bin_size = bin_size
      @bins = Hash.new(0)
      @min_value = Float::INFINITY
      @max_value = -Float::INFINITY

      compute_profile(elements)
    end

    # Find gaps in the projection profile
    # @param min_gap_size [Float] minimum gap size to detect
    # @return [Array<Array<Float>>] array of [start, end] gap ranges
    def find_gaps(min_gap_size: 3.0)
      return [] if @bins.empty?

      gaps = []
      gap_start = nil
      last_filled = nil

      (min_bin..max_bin).each do |bin|
        value = @bins[bin]

        if value.positive?
          if gap_start && last_filled
            gap_end = bin * @bin_size
            gap_size = gap_end - gap_start
            gaps << [gap_start, gap_end] if gap_size >= min_gap_size
          end
          gap_start = nil
          last_filled = bin * @bin_size + @bin_size
        elsif last_filled && gap_start.nil?
          gap_start = last_filled
        end
      end

      gaps
    end

    # Get midpoints of gaps (useful for column detection)
    # @param min_gap_size [Float] minimum gap size
    # @return [Array<Float>] gap midpoint positions
    def gap_midpoints(min_gap_size: 3.0)
      find_gaps(min_gap_size: min_gap_size).map { |start, stop| (start + stop) / 2.0 }
    end

    # Get value at a specific position
    # @param position [Float] position to query
    # @return [Integer] count at that position
    def [](position)
      bin = (position / @bin_size).floor
      @bins[bin]
    end

    # Check if a position is in a gap
    # @param position [Float] position to check
    # @param min_gap_size [Float] minimum gap size
    # @return [Boolean] true if position is in a gap
    def in_gap?(position, min_gap_size: 3.0)
      find_gaps(min_gap_size: min_gap_size).any? do |gap_start, gap_end|
        position >= gap_start && position <= gap_end
      end
    end

    private

    def compute_profile(elements)
      elements.each do |element|
        if @orientation == :horizontal
          # For horizontal profile, we project onto the X axis
          add_range(element.left, element.right)
          @min_value = [@min_value, element.top].min
          @max_value = [@max_value, element.bottom].max
        else
          # For vertical profile, we project onto the Y axis
          add_range(element.top, element.bottom)
          @min_value = [@min_value, element.left].min
          @max_value = [@max_value, element.right].max
        end
      end
    end

    def add_range(start_pos, end_pos)
      start_bin = (start_pos / @bin_size).floor
      end_bin = (end_pos / @bin_size).floor

      (start_bin..end_bin).each { |bin| @bins[bin] += 1 }
    end

    def min_bin
      @bins.keys.min || 0
    end

    def max_bin
      @bins.keys.max || 0
    end
  end
end
