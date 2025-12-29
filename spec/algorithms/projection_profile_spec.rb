# frozen_string_literal: true

RSpec.describe Tabula::ProjectionProfile do
  describe "horizontal profile" do
    let(:elements) do
      [
        Tabula::Rectangle.new(10, 0, 20, 10),   # 0-20
        Tabula::Rectangle.new(10, 25, 20, 10),  # 25-45
        Tabula::Rectangle.new(10, 50, 30, 10)   # 50-80
      ]
    end

    let(:profile) { described_class.new(elements, orientation: :horizontal) }

    describe "#find_gaps" do
      it "finds gaps between elements" do
        gaps = profile.find_gaps(min_gap_size: 3.0)
        expect(gaps.size).to eq(2)
        expect(gaps[0][0]).to be_between(20, 22)
        expect(gaps[0][1]).to be_between(24, 26)
      end
    end

    describe "#gap_midpoints" do
      it "returns midpoints of gaps" do
        midpoints = profile.gap_midpoints(min_gap_size: 3.0)
        expect(midpoints.size).to eq(2)
      end
    end

    describe "#in_gap?" do
      it "returns true for position in gap" do
        expect(profile.in_gap?(22, min_gap_size: 3.0)).to be true
      end

      it "returns false for position in element" do
        expect(profile.in_gap?(10, min_gap_size: 3.0)).to be false
      end
    end
  end

  describe "vertical profile" do
    let(:elements) do
      [
        Tabula::Rectangle.new(0, 10, 10, 20),   # y: 0-20
        Tabula::Rectangle.new(30, 10, 10, 20),  # y: 30-50
        Tabula::Rectangle.new(60, 10, 10, 20)   # y: 60-80
      ]
    end

    let(:profile) { described_class.new(elements, orientation: :vertical) }

    describe "#find_gaps" do
      it "finds vertical gaps" do
        gaps = profile.find_gaps(min_gap_size: 5.0)
        expect(gaps.size).to eq(2)
      end
    end
  end
end
