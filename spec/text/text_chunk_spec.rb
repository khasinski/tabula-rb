# frozen_string_literal: true

RSpec.describe Tabula::TextChunk do
  let(:element1) { Tabula::TextElement.new(top: 10, left: 0, width: 5, height: 10, text: "H") }
  let(:element2) { Tabula::TextElement.new(top: 10, left: 5, width: 5, height: 10, text: "i") }

  describe "#initialize" do
    it "creates from a single element" do
      chunk = described_class.new(element1)
      expect(chunk.text).to eq("H")
      expect(chunk.left).to eq(0)
      expect(chunk.width).to eq(5)
    end

    it "creates empty chunk" do
      chunk = described_class.new
      expect(chunk.empty?).to be true
    end
  end

  describe "#add" do
    it "adds elements and expands bounds" do
      chunk = described_class.new(element1)
      chunk.add(element2)

      expect(chunk.text).to eq("Hi")
      expect(chunk.left).to eq(0)
      expect(chunk.right).to eq(10)
    end
  end

  describe "#text" do
    it "returns normalized text by default" do
      chunk = described_class.new(element1)
      chunk.add(element2)
      expect(chunk.text).to eq("Hi")
    end

    it "can return unnormalized text" do
      chunk = described_class.new(element1)
      chunk.add(element2)
      expect(chunk.text(normalize: false)).to eq("Hi")
    end
  end

  describe "#same_char?" do
    it "returns true when all elements are same char" do
      e1 = Tabula::TextElement.new(top: 10, left: 0, width: 5, height: 10, text: "-")
      e2 = Tabula::TextElement.new(top: 10, left: 5, width: 5, height: 10, text: "-")
      chunk = described_class.new(e1)
      chunk.add(e2)

      expect(chunk.same_char?(["-"])).to be true
    end

    it "returns false for mixed characters" do
      chunk = described_class.new(element1)
      chunk.add(element2)
      expect(chunk.same_char?(["H"])).to be false
    end
  end

  describe "#split_at" do
    it "splits chunk at index" do
      chunk = described_class.new(element1)
      chunk.add(element2)

      left, right = chunk.split_at(1)
      expect(left.text).to eq("H")
      expect(right.text).to eq("i")
    end
  end

  describe ".group_by_lines" do
    it "groups chunks into lines" do
      c1 = described_class.new(Tabula::TextElement.new(top: 10, left: 0, width: 20, height: 10, text: "Hello"))
      c2 = described_class.new(Tabula::TextElement.new(top: 10, left: 25, width: 20, height: 10, text: "World"))
      c3 = described_class.new(Tabula::TextElement.new(top: 30, left: 0, width: 20, height: 10, text: "Next"))

      lines = described_class.group_by_lines([c1, c2, c3])
      expect(lines.size).to eq(2)
      expect(lines[0].text).to eq("Hello World")
      expect(lines[1].text).to eq("Next")
    end
  end
end
