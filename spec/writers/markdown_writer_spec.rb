# frozen_string_literal: true

RSpec.describe Tabula::Writers::MarkdownWriter do
  let(:table) do
    t = Tabula::Table.new
    cell1 = Tabula::Cell.new(0, 0, 50, 20)
    cell1.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: 'Name'))
    cell2 = Tabula::Cell.new(0, 50, 50, 20)
    cell2.add(Tabula::TextElement.new(top: 5, left: 55, width: 20, height: 10, text: 'Age'))
    cell3 = Tabula::Cell.new(20, 0, 50, 20)
    cell3.add(Tabula::TextElement.new(top: 25, left: 5, width: 20, height: 10, text: 'Alice'))
    cell4 = Tabula::Cell.new(20, 50, 50, 20)
    cell4.add(Tabula::TextElement.new(top: 25, left: 55, width: 20, height: 10, text: '30'))

    t.add(0, 0, cell1)
    t.add(0, 1, cell2)
    t.add(1, 0, cell3)
    t.add(1, 1, cell4)
    t
  end

  describe '.to_string' do
    it 'converts tables to Markdown string' do
      result = described_class.to_string([table])
      expected = <<~MARKDOWN
        | Name | Age |
        | --- | --- |
        | Alice | 30 |
      MARKDOWN
      expect(result).to eq(expected)
    end
  end

  describe 'alignment options' do
    it 'uses left alignment' do
      result = described_class.to_string([table], alignment: :left)
      expect(result).to include('| :--- | :--- |')
    end

    it 'uses center alignment' do
      result = described_class.to_string([table], alignment: :center)
      expect(result).to include('| :---: | :---: |')
    end

    it 'uses right alignment' do
      result = described_class.to_string([table], alignment: :right)
      expect(result).to include('| ---: | ---: |')
    end
  end

  describe 'escaping' do
    it 'escapes pipe characters' do
      t = Tabula::Table.new
      cell = Tabula::Cell.new(0, 0, 50, 20)
      cell.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: 'A|B'))
      t.add(0, 0, cell)

      result = described_class.to_string([t])
      expect(result).to include('A\\|B')
    end

    it 'normalizes whitespace' do
      t = Tabula::Table.new
      cell = Tabula::Cell.new(0, 0, 50, 20)
      cell.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: 'Hello  World'))
      t.add(0, 0, cell)

      result = described_class.to_string([t])
      expect(result).to include('Hello World')
    end
  end

  describe 'multiple tables' do
    it 'separates tables with blank lines' do
      result = described_class.to_string([table, table])
      lines = result.split("\n")

      # First table: 3 lines, blank line, second table: 3 lines
      expect(lines[3]).to eq('')
    end
  end

  describe 'empty tables' do
    it 'handles empty tables gracefully' do
      empty_table = Tabula::Table.new
      result = described_class.to_string([empty_table])
      expect(result).to eq('')
    end
  end
end
