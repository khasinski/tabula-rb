# frozen_string_literal: true

RSpec.describe Tabula::Ruling do
  describe 'basic properties' do
    let(:ruling) { described_class.new(0, 0, 10, 10) }

    it 'calculates width correctly' do
      expect(ruling.width).to eq(10.0)
    end

    it 'calculates height correctly' do
      expect(ruling.height).to eq(10.0)
    end

    it 'has correct string representation' do
      expect(ruling.to_s).to include('Ruling')
    end

    it 'equals itself' do
      expect(ruling).to eq(ruling)
    end

    it 'does not equal different ruling' do
      other = described_class.new(0, 0, 11, 10)
      expect(ruling).not_to eq(other)
    end

    it 'is not equal to non-ruling objects' do
      expect(ruling).not_to eq('test')
    end
  end

  describe '#nearly_intersects?' do
    it 'detects near intersections between horizontal and vertical' do
      horizontal = described_class.new(0, 50, 100, 50)  # horizontal line at y=50
      vertical = described_class.new(50, 0, 50, 100)    # vertical line at x=50

      expect(horizontal.nearly_intersects?(vertical)).to be true
    end

    it 'returns false for parallel lines' do
      r1 = described_class.new(0, 10, 100, 10)  # horizontal at y=10
      r2 = described_class.new(0, 20, 100, 20)  # horizontal at y=20

      expect(r1.nearly_intersects?(r2)).to be false
    end
  end

  describe 'orientation detection' do
    it 'detects horizontal ruling' do
      ruling = described_class.new(0, 0, 100, 0)
      expect(ruling.horizontal?).to be true
      expect(ruling.vertical?).to be false
      expect(ruling.oblique?).to be false
    end

    it 'detects vertical ruling' do
      ruling = described_class.new(0, 0, 0, 100)
      expect(ruling.horizontal?).to be false
      expect(ruling.vertical?).to be true
      expect(ruling.oblique?).to be false
    end

    it 'detects oblique ruling' do
      ruling = described_class.new(0, 0, 50, 50)
      expect(ruling.horizontal?).to be false
      expect(ruling.vertical?).to be false
      expect(ruling.oblique?).to be true
    end

    it 'detects nearly horizontal as horizontal' do
      ruling = described_class.new(0, 0, 100, 0.5)
      expect(ruling.horizontal?).to be true
    end

    it 'detects nearly vertical as vertical' do
      ruling = described_class.new(0, 0, 0.5, 100)
      expect(ruling.vertical?).to be true
    end
  end

  describe '#colinear_with?' do
    it 'detects colinear horizontal rulings' do
      r1 = described_class.new(0, 10, 100, 10)
      r2 = described_class.new(50, 10, 150, 10)

      expect(r1.colinear_with?(r2)).to be true
    end

    it 'detects colinear vertical rulings' do
      r1 = described_class.new(10, 0, 10, 100)
      r2 = described_class.new(10, 50, 10, 150)

      expect(r1.colinear_with?(r2)).to be true
    end

    it 'rejects non-colinear rulings' do
      r1 = described_class.new(0, 10, 100, 10)
      r2 = described_class.new(0, 20, 100, 20)

      expect(r1.colinear_with?(r2)).to be false
    end
  end

  describe '#position' do
    it 'returns y position for horizontal ruling' do
      ruling = described_class.new(0, 10, 100, 10)
      expect(ruling.position).to eq(10.0)
    end

    it 'returns x position for vertical ruling' do
      ruling = described_class.new(10, 0, 10, 100)
      expect(ruling.position).to eq(10.0)
    end
  end

  describe '#position=' do
    it 'sets y position for horizontal ruling' do
      ruling = described_class.new(0, 10, 100, 10)
      ruling.position = 20
      expect(ruling.y1).to eq(20.0)
      expect(ruling.y2).to eq(20.0)
    end

    it 'sets x position for vertical ruling' do
      ruling = described_class.new(10, 0, 10, 100)
      ruling.position = 20
      expect(ruling.x1).to eq(20.0)
      expect(ruling.x2).to eq(20.0)
    end
  end

  describe '#start and #end' do
    it 'returns correct values for horizontal ruling' do
      ruling = described_class.new(0, 10, 100, 10)
      expect(ruling.start).to eq(0.0)
      expect(ruling.end).to eq(100.0)
    end

    it 'returns correct values for vertical ruling' do
      ruling = described_class.new(10, 0, 10, 100)
      expect(ruling.start).to eq(0.0)
      expect(ruling.end).to eq(100.0)
    end
  end

  describe '.collapse_oriented_rulings' do
    it 'collapses colinear horizontal rulings' do
      rulings = [
        described_class.new(0, 10, 50, 10),
        described_class.new(40, 10, 100, 10),
        described_class.new(0, 50, 100, 50)
      ]

      collapsed = described_class.collapse_oriented_rulings(rulings)

      # Should have 2 distinct horizontal lines
      horizontal = collapsed.select(&:horizontal?)
      expect(horizontal.size).to eq(2)
    end

    it 'collapses colinear vertical rulings' do
      rulings = [
        described_class.new(10, 0, 10, 50),
        described_class.new(10, 40, 10, 100)
      ]

      collapsed = described_class.collapse_oriented_rulings(rulings)

      vertical = collapsed.select(&:vertical?)
      expect(vertical.size).to eq(1)
    end
  end

  describe '.find_intersections' do
    it 'finds intersection points' do
      horizontal = [
        described_class.new(0, 10, 100, 10),
        described_class.new(0, 50, 100, 50)
      ]
      vertical = [
        described_class.new(25, 0, 25, 100),
        described_class.new(75, 0, 75, 100)
      ]

      intersections = described_class.find_intersections(horizontal, vertical)

      expect(intersections.size).to eq(4)
    end
  end

  describe '#expand' do
    it 'expands horizontal ruling' do
      ruling = described_class.new(10, 10, 50, 10)
      expanded = ruling.expand(5)

      expect(expanded.x1).to eq(5.0)
      expect(expanded.x2).to eq(55.0)
    end

    it 'expands vertical ruling' do
      ruling = described_class.new(10, 10, 10, 50)
      expanded = ruling.expand(5)

      expect(expanded.y1).to eq(5.0)
      expect(expanded.y2).to eq(55.0)
    end
  end
end
