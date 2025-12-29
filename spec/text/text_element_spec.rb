# frozen_string_literal: true

RSpec.describe Tabula::TextElement do
  describe '#initialize' do
    it 'creates a text element with all attributes' do
      element = described_class.new(
        top: 10,
        left: 20,
        width: 5,
        height: 12,
        text: 'A',
        font_name: 'Arial',
        font_size: 12.0,
        width_of_space: 4.0
      )

      expect(element.top).to eq(10.0)
      expect(element.left).to eq(20.0)
      expect(element.width).to eq(5.0)
      expect(element.height).to eq(12.0)
      expect(element.text).to eq('A')
      expect(element.font_name).to eq('Arial')
      expect(element.font_size).to eq(12.0)
      expect(element.width_of_space).to eq(4.0)
    end
  end

  describe '#whitespace?' do
    it 'returns true for empty text' do
      element = described_class.new(top: 0, left: 0, width: 5, height: 10, text: '')
      expect(element.whitespace?).to be true
    end

    it 'returns true for whitespace-only text' do
      element = described_class.new(top: 0, left: 0, width: 5, height: 10, text: '   ')
      expect(element.whitespace?).to be true
    end

    it 'returns false for non-whitespace text' do
      element = described_class.new(top: 0, left: 0, width: 5, height: 10, text: 'A')
      expect(element.whitespace?).to be false
    end
  end

  describe '#ltr? and #rtl?' do
    it 'defaults to LTR' do
      element = described_class.new(top: 0, left: 0, width: 5, height: 10, text: 'A')
      expect(element.ltr?).to be true
      expect(element.rtl?).to be false
    end

    it 'can be RTL' do
      element = described_class.new(
        top: 0, left: 0, width: 5, height: 10, text: 'A',
        direction: Tabula::TextElement::DIRECTION_RTL
      )
      expect(element.ltr?).to be false
      expect(element.rtl?).to be true
    end
  end

  describe '.merge_words' do
    let(:elements) do
      [
        described_class.new(top: 10, left: 0, width: 5, height: 10, text: 'H', width_of_space: 4),
        described_class.new(top: 10, left: 5, width: 5, height: 10, text: 'i', width_of_space: 4),
        described_class.new(top: 10, left: 20, width: 5, height: 10, text: 'W', width_of_space: 4),
        described_class.new(top: 10, left: 25, width: 5, height: 10, text: 'o', width_of_space: 4),
        described_class.new(top: 10, left: 30, width: 5, height: 10, text: 'r', width_of_space: 4),
        described_class.new(top: 10, left: 35, width: 5, height: 10, text: 'l', width_of_space: 4),
        described_class.new(top: 10, left: 40, width: 5, height: 10, text: 'd', width_of_space: 4)
      ]
    end

    it 'merges adjacent characters into words' do
      chunks = described_class.merge_words(elements)
      expect(chunks.size).to eq(2)
      expect(chunks[0].text).to eq('Hi')
      expect(chunks[1].text).to eq('World')
    end

    it 'returns empty array for empty input' do
      expect(described_class.merge_words([])).to be_empty
    end
  end
end
