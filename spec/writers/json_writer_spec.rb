# frozen_string_literal: true

require "json"

RSpec.describe Tabula::Writers::JSONWriter do
  let(:table) do
    t = Tabula::Table.new(extraction_method: "test", page_number: 1)
    cell1 = Tabula::Cell.new(0, 0, 50, 20)
    cell1.add(Tabula::TextElement.new(top: 5, left: 5, width: 20, height: 10, text: "Name"))
    cell2 = Tabula::Cell.new(0, 50, 50, 20)
    cell2.add(Tabula::TextElement.new(top: 5, left: 55, width: 20, height: 10, text: "Age"))

    t.add(0, 0, cell1)
    t.add(0, 1, cell2)
    t
  end

  describe ".to_string" do
    it "converts tables to JSON string" do
      result = described_class.to_string([table])
      parsed = JSON.parse(result)

      expect(parsed).to be_an(Array)
      expect(parsed.size).to eq(1)
      expect(parsed[0]["extraction_method"]).to eq("test")
      expect(parsed[0]["data"]).to eq([["Name", "Age"]])
    end
  end

  describe "without metadata" do
    it "includes only data" do
      result = described_class.to_string([table], include_metadata: false)
      parsed = JSON.parse(result)

      expect(parsed[0].keys).to eq(["data"])
    end
  end

  describe "pretty printing" do
    it "formats JSON with indentation" do
      result = described_class.to_string([table], pretty: true)
      expect(result).to include("\n")
      expect(result).to include("  ")
    end
  end
end
