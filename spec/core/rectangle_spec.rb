# frozen_string_literal: true

RSpec.describe Tabula::Rectangle do
  describe '#initialize' do
    it 'creates a rectangle with position and dimensions' do
      rect = described_class.new(10, 20, 100, 50)
      expect(rect.top).to eq(10.0)
      expect(rect.left).to eq(20.0)
      expect(rect.width).to eq(100.0)
      expect(rect.height).to eq(50.0)
    end
  end

  describe '.from_bounds' do
    it 'creates rectangle from top, left, bottom, right' do
      rect = described_class.from_bounds(10, 20, 60, 120)
      expect(rect.top).to eq(10.0)
      expect(rect.left).to eq(20.0)
      expect(rect.bottom).to eq(60.0)
      expect(rect.right).to eq(120.0)
    end
  end

  describe '.from_points' do
    it 'creates rectangle from two points' do
      p1 = Tabula::Point.new(20, 10)
      p2 = Tabula::Point.new(120, 60)
      rect = described_class.from_points(p1, p2)
      expect(rect.left).to eq(20.0)
      expect(rect.top).to eq(10.0)
      expect(rect.right).to eq(120.0)
      expect(rect.bottom).to eq(60.0)
    end
  end

  describe '.bounding_box_of' do
    it 'computes bounding box of multiple rectangles' do
      r1 = described_class.new(10, 20, 50, 30)
      r2 = described_class.new(30, 10, 60, 40)
      bbox = described_class.bounding_box_of([r1, r2])
      expect(bbox.top).to eq(10.0)
      expect(bbox.left).to eq(10.0)
      expect(bbox.bottom).to eq(70.0)
      expect(bbox.right).to eq(70.0)
    end

    it 'returns nil for empty array' do
      expect(described_class.bounding_box_of([])).to be_nil
    end
  end

  describe '#area' do
    it 'calculates area' do
      rect = described_class.new(0, 0, 10, 20)
      expect(rect.area).to eq(200.0)
    end
  end

  describe '#center' do
    it 'returns center point' do
      rect = described_class.new(10, 20, 100, 50)
      center = rect.center
      expect(center.x).to eq(70.0)
      expect(center.y).to eq(35.0)
    end
  end

  describe '#vertical_overlap' do
    it 'calculates vertical overlap' do
      r1 = described_class.new(10, 0, 100, 50)
      r2 = described_class.new(40, 0, 100, 50)
      expect(r1.vertical_overlap(r2)).to eq(20.0)
    end

    it 'returns 0 for non-overlapping rectangles' do
      r1 = described_class.new(10, 0, 100, 20)
      r2 = described_class.new(40, 0, 100, 50)
      expect(r1.vertical_overlap(r2)).to eq(0.0)
    end
  end

  describe '#horizontally_overlaps?' do
    it 'returns true for horizontally overlapping rectangles' do
      r1 = described_class.new(0, 10, 50, 20)
      r2 = described_class.new(0, 40, 30, 20)
      expect(r1.horizontally_overlaps?(r2)).to be true
    end

    it 'returns false for non-overlapping rectangles' do
      r1 = described_class.new(0, 10, 20, 20)
      r2 = described_class.new(0, 40, 30, 20)
      expect(r1.horizontally_overlaps?(r2)).to be false
    end
  end

  describe '#contains?' do
    it 'returns true when fully containing another rectangle' do
      outer = described_class.new(0, 0, 100, 100)
      inner = described_class.new(10, 10, 50, 50)
      expect(outer.contains?(inner)).to be true
    end

    it 'returns false when not fully containing' do
      r1 = described_class.new(0, 0, 50, 50)
      r2 = described_class.new(25, 25, 50, 50)
      expect(r1.contains?(r2)).to be false
    end
  end

  describe '#intersects?' do
    it 'returns true for intersecting rectangles' do
      r1 = described_class.new(0, 0, 50, 50)
      r2 = described_class.new(25, 25, 50, 50)
      expect(r1.intersects?(r2)).to be true
    end

    it 'returns false for non-intersecting rectangles' do
      r1 = described_class.new(0, 0, 50, 50)
      r2 = described_class.new(100, 100, 50, 50)
      expect(r1.intersects?(r2)).to be false
    end
  end

  describe '#merge' do
    it 'returns bounding box of both rectangles' do
      # r1: top=10, left=20, width=30, height=40 → bottom=50, right=50
      # r2: top=30, left=10, width=50, height=60 → bottom=90, right=60
      r1 = described_class.new(10, 20, 30, 40)
      r2 = described_class.new(30, 10, 50, 60)
      merged = r1.merge(r2)
      expect(merged.top).to eq(10.0)
      expect(merged.left).to eq(10.0)
      expect(merged.bottom).to eq(90.0)
      expect(merged.right).to eq(60.0)
    end
  end

  describe '#intersection' do
    it 'returns intersection rectangle' do
      r1 = described_class.new(0, 0, 50, 50)
      r2 = described_class.new(25, 25, 50, 50)
      intersection = r1.intersection(r2)
      expect(intersection.top).to eq(25.0)
      expect(intersection.left).to eq(25.0)
      expect(intersection.bottom).to eq(50.0)
      expect(intersection.right).to eq(50.0)
    end

    it 'returns nil for non-intersecting rectangles' do
      r1 = described_class.new(0, 0, 20, 20)
      r2 = described_class.new(50, 50, 20, 20)
      expect(r1.intersection(r2)).to be_nil
    end
  end

  describe '#<=>' do
    it 'sorts by top then left' do
      r1 = described_class.new(10, 20, 10, 10)
      r2 = described_class.new(10, 30, 10, 10)
      r3 = described_class.new(20, 10, 10, 10)
      sorted = [r3, r2, r1].sort
      expect(sorted).to eq([r1, r2, r3])
    end
  end
end
