# frozen_string_literal: true

RSpec.describe Tabula::SpatialIndex do
  let(:index) { described_class.new(cell_size: 10) }

  let(:r1) { Tabula::Rectangle.new(5, 5, 10, 10) }
  let(:r2) { Tabula::Rectangle.new(20, 20, 10, 10) }
  let(:r3) { Tabula::Rectangle.new(50, 50, 10, 10) }

  before do
    index.add(r1)
    index.add(r2)
    index.add(r3)
  end

  describe "#add" do
    it "adds rectangles to the index" do
      expect(index.size).to eq(3)
    end
  end

  describe "#intersects" do
    it "finds intersecting rectangles" do
      query = Tabula::Rectangle.new(10, 10, 20, 20)
      results = index.intersects(query)
      expect(results).to contain_exactly(r1, r2)
    end

    it "returns empty array when no intersections" do
      query = Tabula::Rectangle.new(100, 100, 10, 10)
      expect(index.intersects(query)).to be_empty
    end
  end

  describe "#contains" do
    it "finds contained rectangles" do
      query = Tabula::Rectangle.new(0, 0, 40, 40)
      results = index.contains(query)
      expect(results).to contain_exactly(r1, r2)
    end
  end

  describe "#at_point" do
    it "finds rectangles at a point" do
      point = Tabula::Point.new(10, 10)
      results = index.at_point(point)
      expect(results).to contain_exactly(r1)
    end

    it "returns empty array when point not in any rectangle" do
      point = Tabula::Point.new(100, 100)
      expect(index.at_point(point)).to be_empty
    end
  end

  describe "#nearby" do
    it "finds rectangles within distance" do
      query = Tabula::Rectangle.new(15, 15, 1, 1)
      results = index.nearby(query, 10)
      expect(results).to contain_exactly(r1, r2)
    end
  end

  describe "#bounds" do
    it "returns bounding box of all rectangles" do
      bounds = index.bounds
      expect(bounds.top).to eq(5.0)
      expect(bounds.left).to eq(5.0)
      expect(bounds.bottom).to eq(60.0)
      expect(bounds.right).to eq(60.0)
    end
  end

  describe "#empty?" do
    it "returns true for empty index" do
      expect(described_class.new.empty?).to be true
    end

    it "returns false for non-empty index" do
      expect(index.empty?).to be false
    end
  end

  describe "#clear" do
    it "removes all rectangles" do
      index.clear
      expect(index.empty?).to be true
    end
  end
end
