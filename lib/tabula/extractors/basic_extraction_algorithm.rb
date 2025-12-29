# frozen_string_literal: true

module Tabula
  module Extractors
    # Stream-mode extraction algorithm.
    # Extracts tables by analyzing text positions and gaps without relying on ruling lines.
    class Basic < ExtractionAlgorithm
      # @param columns [Array<Float>, nil] explicit column positions
      # @param guess [Boolean] whether to guess column positions
      def initialize(columns: nil, guess: true, **options)
        super(**options)
        @columns = columns
        @guess = guess
      end

      # Extract tables from a page
      # @param page [Page] page to extract from
      # @return [Array<Table>]
      def extract(page)
        return [] if page.text_elements.empty?

        # Get text chunks and lines
        chunks = page.text_chunks
        return [] if chunks.empty?

        lines = TextChunk.group_by_lines(chunks)
        return [] if lines.empty?

        # Determine column positions
        column_positions = determine_columns(lines, page)

        # Build table
        table = build_table(lines, column_positions, page.page_number)
        table.empty? ? [] : [table]
      end

      private

      def determine_columns(lines, page)
        if @columns
          # Use explicit columns
          @columns.sort
        elsif page.vertical_rulings.any?
          # Use vertical ruling positions
          page.vertical_rulings.map(&:x1).sort.uniq
        elsif @guess
          # Guess columns from text gaps
          guess_column_positions(lines)
        else
          # No column separators - single column
          []
        end
      end

      def guess_column_positions(lines)
        return [] if lines.empty?

        # Collect all gap positions from all lines
        all_gaps = []
        lines.each do |line|
          gaps = line.gap_positions
          all_gaps.concat(gaps)
        end

        return [] if all_gaps.empty?

        # Cluster gaps that appear in multiple lines
        clustered = cluster_positions(all_gaps, tolerance: 5.0)

        # Only keep gaps that appear in at least 30% of lines
        min_occurrences = (lines.size * 0.3).ceil
        frequent = clustered.select { |_, count| count >= min_occurrences }

        frequent.keys.sort
      end

      def cluster_positions(positions, tolerance:)
        return {} if positions.empty?

        sorted = positions.sort
        clusters = {}
        current_cluster = [sorted.first]

        sorted[1..].each do |pos|
          if (pos - current_cluster.last) <= tolerance
            current_cluster << pos
          else
            avg = current_cluster.sum / current_cluster.size
            clusters[avg] = current_cluster.size
            current_cluster = [pos]
          end
        end

        unless current_cluster.empty?
          avg = current_cluster.sum / current_cluster.size
          clusters[avg] = current_cluster.size
        end

        clusters
      end

      def build_table(lines, column_positions, page_number)
        table = Table.new(extraction_method: name, page_number: page_number)

        lines.each_with_index do |line, row_idx|
          assign_chunks_to_columns(line, column_positions, table, row_idx)
        end

        table
      end

      def assign_chunks_to_columns(line, column_positions, table, row_idx)
        if column_positions.empty?
          # Single column
          cell = create_cell_from_line(line)
          table.add(row_idx, 0, cell)
        else
          # Multiple columns - assign chunks to appropriate columns
          columns = split_line_by_columns(line, column_positions)
          columns.each_with_index do |chunks, col_idx|
            cell = create_cell_from_chunks(chunks)
            table.add(row_idx, col_idx, cell)
          end
        end
      end

      def split_line_by_columns(line, column_positions)
        # Create column boundaries
        boundaries = [line.left, *column_positions, Float::INFINITY]

        # Initialize columns
        num_columns = boundaries.size - 1
        columns = Array.new(num_columns) { [] }

        # Assign each chunk to a column
        line.sorted_chunks.each do |chunk|
          chunk_center = chunk.left + chunk.width / 2.0
          col_idx = find_column_index(chunk_center, boundaries)
          columns[col_idx] << chunk
        end

        columns
      end

      def find_column_index(x, boundaries)
        boundaries.each_cons(2).with_index do |(left, right), idx|
          return idx if x >= left && x < right
        end
        boundaries.size - 2 # Last column
      end

      def create_cell_from_line(line)
        cell = Cell.new(line.top, line.left, line.width, line.height)
        line.chunks.each { |chunk| cell.add(chunk) }
        cell
      end

      def create_cell_from_chunks(chunks)
        return Cell.empty if chunks.empty?

        bounds = Rectangle.bounding_box_of(chunks)
        cell = Cell.new(bounds.top, bounds.left, bounds.width, bounds.height)
        chunks.each { |chunk| cell.add(chunk) }
        cell
      end
    end
  end
end
