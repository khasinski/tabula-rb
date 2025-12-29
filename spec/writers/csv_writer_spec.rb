# frozen_string_literal: true

RSpec.describe Tabula::Writers::CSVWriter do
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
    it 'converts tables to CSV string' do
      result = described_class.to_string([table])
      expect(result).to eq("Name,Age\nAlice,30\n")
    end
  end

  describe 'custom separator' do
    it 'uses semicolon separator' do
      result = described_class.to_string([table], separator: ';')
      expect(result).to eq("Name;Age\nAlice;30\n")
    end
  end
end
