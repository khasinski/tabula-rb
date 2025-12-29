# frozen_string_literal: true

RSpec.describe Tabula::Table do
  let(:table) { described_class.new(extraction_method: 'test', page_number: 1) }

  describe '#initialize' do
    it 'creates an empty table' do
      expect(table.empty?).to be true
      expect(table.row_count).to eq(0)
      expect(table.col_count).to eq(0)
    end
  end

  describe '#add' do
    it 'adds cells and updates dimensions' do
      cell1 = Tabula::Cell.new(0, 0, 50, 20)
      cell2 = Tabula::Cell.new(0, 50, 50, 20)
      cell3 = Tabula::Cell.new(20, 0, 50, 20)

      table.add(0, 0, cell1)
      table.add(0, 1, cell2)
      table.add(1, 0, cell3)

      expect(table.row_count).to eq(2)
      expect(table.col_count).to eq(2)
    end
  end

  describe '#get_cell' do
    it 'returns cell at position' do
      cell = Tabula::Cell.new(0, 0, 50, 20)
      cell.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: 'Test'))
      table.add(0, 0, cell)

      expect(table.get_cell(0, 0).text).to eq('Test')
    end

    it 'returns empty cell for missing position' do
      expect(table.get_cell(5, 5).empty?).to be true
    end
  end

  describe '#rows' do
    it 'returns 2D array of cells' do
      cell1 = Tabula::Cell.new(0, 0, 50, 20)
      cell2 = Tabula::Cell.new(0, 50, 50, 20)
      table.add(0, 0, cell1)
      table.add(0, 1, cell2)

      rows = table.rows
      expect(rows.size).to eq(1)
      expect(rows[0].size).to eq(2)
    end
  end

  describe '#to_a' do
    it 'returns 2D array of strings' do
      cell1 = Tabula::Cell.new(0, 0, 50, 20)
      cell1.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: 'A'))
      cell2 = Tabula::Cell.new(0, 50, 50, 20)
      cell2.add(Tabula::TextElement.new(top: 5, left: 55, width: 20, height: 10, text: 'B'))

      table.add(0, 0, cell1)
      table.add(0, 1, cell2)

      expect(table.to_a).to eq([%w[A B]])
    end
  end

  describe '#to_csv' do
    it 'returns CSV string' do
      cell1 = Tabula::Cell.new(0, 0, 50, 20)
      cell1.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: 'Name'))
      cell2 = Tabula::Cell.new(0, 50, 50, 20)
      cell2.add(Tabula::TextElement.new(top: 5, left: 55, width: 20, height: 10, text: 'Age'))

      table.add(0, 0, cell1)
      table.add(0, 1, cell2)

      expect(table.to_csv).to eq("Name,Age\n")
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      hash = table.to_h

      expect(hash).to include(:extraction_method, :page_number, :data)
      expect(hash[:extraction_method]).to eq('test')
      expect(hash[:page_number]).to eq(1)
    end
  end

  describe '#each_cell' do
    it 'iterates over all cells' do
      cell1 = Tabula::Cell.new(0, 0, 50, 20)
      cell2 = Tabula::Cell.new(0, 50, 50, 20)
      table.add(0, 0, cell1)
      table.add(0, 1, cell2)

      cells = []
      table.each_cell { |r, c, cell| cells << [r, c, cell] }

      expect(cells.size).to eq(2)
    end
  end
end
