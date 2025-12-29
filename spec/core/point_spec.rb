# frozen_string_literal: true

RSpec.describe Tabula::Point do
  describe "#initialize" do
    it "creates a point with x and y coordinates" do
      point = described_class.new(10, 20)
      expect(point.x).to eq(10.0)
      expect(point.y).to eq(20.0)
    end

    it "converts integers to floats" do
      point = described_class.new(5, 10)
      expect(point.x).to be_a(Float)
      expect(point.y).to be_a(Float)
    end
  end

  describe "#to_a" do
    it "returns coordinates as array" do
      point = described_class.new(10, 20)
      expect(point.to_a).to eq([10.0, 20.0])
    end
  end

  describe "#==" do
    it "returns true for equal points" do
      p1 = described_class.new(10, 20)
      p2 = described_class.new(10, 20)
      expect(p1).to eq(p2)
    end

    it "returns false for different points" do
      p1 = described_class.new(10, 20)
      p2 = described_class.new(10, 30)
      expect(p1).not_to eq(p2)
    end
  end

  describe "#distance_to" do
    it "calculates distance between two points" do
      p1 = described_class.new(0, 0)
      p2 = described_class.new(3, 4)
      expect(p1.distance_to(p2)).to eq(5.0)
    end
  end

  describe "arithmetic operations" do
    let(:p1) { described_class.new(10, 20) }
    let(:p2) { described_class.new(5, 10) }

    it "adds two points" do
      result = p1 + p2
      expect(result.x).to eq(15.0)
      expect(result.y).to eq(30.0)
    end

    it "subtracts two points" do
      result = p1 - p2
      expect(result.x).to eq(5.0)
      expect(result.y).to eq(10.0)
    end

    it "multiplies by scalar" do
      result = p1 * 2
      expect(result.x).to eq(20.0)
      expect(result.y).to eq(40.0)
    end

    it "divides by scalar" do
      result = p1 / 2
      expect(result.x).to eq(5.0)
      expect(result.y).to eq(10.0)
    end
  end
end
