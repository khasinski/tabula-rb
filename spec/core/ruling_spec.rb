# frozen_string_literal: true

RSpec.describe Tabula::Ruling do
  describe '#initialize' do
    it 'creates a ruling from coordinates' do
      ruling = described_class.new(10, 20, 100, 20)
      expect(ruling.x1).to eq(10.0)
      expect(ruling.y1).to eq(20.0)
      expect(ruling.x2).to eq(100.0)
      expect(ruling.y2).to eq(20.0)
    end

    it 'normalizes horizontal lines' do
      ruling = described_class.new(100, 20.5, 10, 19.5)
      expect(ruling.x1).to eq(10.0)
      expect(ruling.x2).to eq(100.0)
      expect(ruling.y1).to eq(ruling.y2)
    end

    it 'normalizes vertical lines' do
      ruling = described_class.new(20.5, 100, 19.5, 10)
      expect(ruling.y1).to eq(10.0)
      expect(ruling.y2).to eq(100.0)
      expect(ruling.x1).to eq(ruling.x2)
    end
  end

  describe '#horizontal?' do
    it 'returns true for horizontal lines' do
      ruling = described_class.new(10, 20, 100, 20)
      expect(ruling.horizontal?).to be true
    end

    it 'returns false for vertical lines' do
      ruling = described_class.new(20, 10, 20, 100)
      expect(ruling.horizontal?).to be false
    end
  end

  describe '#vertical?' do
    it 'returns true for vertical lines' do
      ruling = described_class.new(20, 10, 20, 100)
      expect(ruling.vertical?).to be true
    end

    it 'returns false for horizontal lines' do
      ruling = described_class.new(10, 20, 100, 20)
      expect(ruling.vertical?).to be false
    end
  end

  describe '#length' do
    it 'calculates line length' do
      ruling = described_class.new(0, 0, 3, 4)
      expect(ruling.length).to eq(5.0)
    end
  end

  describe '#intersection_point' do
    it 'finds intersection of horizontal and vertical lines' do
      h = described_class.new(0, 50, 100, 50)
      v = described_class.new(30, 0, 30, 100)
      point = h.intersection_point(v)
      expect(point.x).to eq(30.0)
      expect(point.y).to eq(50.0)
    end

    it 'returns nil for parallel lines' do
      h1 = described_class.new(0, 50, 100, 50)
      h2 = described_class.new(0, 60, 100, 60)
      expect(h1.intersection_point(h2)).to be_nil
    end
  end

  describe '#intersects?' do
    it 'returns true when lines cross' do
      h = described_class.new(0, 50, 100, 50)
      v = described_class.new(30, 0, 30, 100)
      expect(h.intersects?(v)).to be true
    end

    it "returns false when lines don't cross" do
      h = described_class.new(0, 50, 20, 50)
      v = described_class.new(30, 0, 30, 100)
      expect(h.intersects?(v)).to be false
    end
  end

  describe '#expand' do
    it 'expands horizontal line' do
      ruling = described_class.new(10, 50, 90, 50)
      expanded = ruling.expand(5)
      expect(expanded.x1).to eq(5.0)
      expect(expanded.x2).to eq(95.0)
    end

    it 'expands vertical line' do
      ruling = described_class.new(50, 10, 50, 90)
      expanded = ruling.expand(5)
      expect(expanded.y1).to eq(5.0)
      expect(expanded.y2).to eq(95.0)
    end
  end

  describe '.find_intersections' do
    it 'finds all intersection points' do
      horizontals = [
        described_class.new(0, 10, 100, 10),
        described_class.new(0, 50, 100, 50)
      ]
      verticals = [
        described_class.new(20, 0, 20, 100),
        described_class.new(80, 0, 80, 100)
      ]
      intersections = described_class.find_intersections(horizontals, verticals)
      expect(intersections.size).to eq(4)
    end
  end

  describe '.collapse_oriented_rulings' do
    it 'collapses colinear rulings' do
      rulings = [
        described_class.new(0, 10, 50, 10),
        described_class.new(60, 10.5, 100, 10.5),
        described_class.new(0, 50, 100, 50)
      ]
      collapsed = described_class.collapse_oriented_rulings(rulings)
      expect(collapsed.size).to eq(2)
    end
  end
end
