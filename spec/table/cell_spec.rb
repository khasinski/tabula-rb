# frozen_string_literal: true

RSpec.describe Tabula::Cell do
  describe '#initialize' do
    it 'creates a cell with dimensions' do
      cell = described_class.new(10, 20, 100, 50)
      expect(cell.top).to eq(10.0)
      expect(cell.left).to eq(20.0)
      expect(cell.width).to eq(100.0)
      expect(cell.height).to eq(50.0)
    end
  end

  describe '.empty' do
    it 'creates a placeholder cell' do
      cell = described_class.empty
      expect(cell.placeholder?).to be true
      expect(cell.empty?).to be true
    end
  end

  describe '#add' do
    it 'adds text elements' do
      cell = described_class.new(0, 0, 100, 50)
      element = Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: 'Hello')
      cell.add(element)

      expect(cell.has_text?).to be true
      expect(cell.text).to eq('Hello')
    end
  end

  describe '#text' do
    it 'combines multiple text elements' do
      cell = described_class.new(0, 0, 100, 50)
      cell.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: 'Hello'))
      cell.add(Tabula::TextElement.new(top: 5, left: 30, width: 20, height: 10, text: 'World'))

      expect(cell.text).to eq('Hello World')
    end
  end

  describe '#empty?' do
    it 'returns true for cell without text' do
      cell = described_class.new(0, 0, 100, 50)
      expect(cell.empty?).to be true
    end

    it 'returns false for cell with text' do
      cell = described_class.new(0, 0, 100, 50)
      cell.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: 'Hi'))
      expect(cell.empty?).to be false
    end
  end

  describe '#blank?' do
    it 'returns true for cell without text elements' do
      cell = described_class.new(0, 0, 100, 50)
      expect(cell.blank?).to be true
    end

    it 'returns true for cell with only whitespace text' do
      cell = described_class.new(0, 0, 100, 50)
      cell.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: '   '))
      expect(cell.blank?).to be true
    end

    it 'returns true for cell with empty text' do
      cell = described_class.new(0, 0, 100, 50)
      cell.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: ''))
      expect(cell.blank?).to be true
    end

    it 'returns false for cell with meaningful text' do
      cell = described_class.new(0, 0, 100, 50)
      cell.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: 'Hello'))
      expect(cell.blank?).to be false
    end

    it 'returns false for cell with text that has leading/trailing whitespace' do
      cell = described_class.new(0, 0, 100, 50)
      cell.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: '  Hi  '))
      expect(cell.blank?).to be false
    end
  end
end
