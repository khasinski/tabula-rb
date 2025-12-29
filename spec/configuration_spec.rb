# frozen_string_literal: true

RSpec.describe Tabula::Configuration do
  describe '#initialize' do
    it 'sets default values' do
      config = described_class.new

      expect(config.orientation_tolerance).to eq(1.0)
      expect(config.intersection_tolerance).to eq(1.0)
      expect(config.ruling_thickness_threshold).to eq(8.0)
      expect(config.word_gap_multiplier).to eq(0.5)
      expect(config.line_gap_multiplier).to eq(0.5)
      expect(config.min_cells).to eq(4)
      expect(config.min_table_dimension).to eq(10.0)
      expect(config.cell_tolerance).to eq(2.0)
      expect(config.min_rows).to eq(2)
      expect(config.overlap_threshold).to eq(0.9)
      expect(config.tabular_ratio_threshold).to eq(0.65)
      expect(config.edge_clustering_tolerance).to eq(8.0)
      expect(config.detection_padding).to eq(2.0)
      expect(config.vertical_comparison_threshold).to eq(0.4)
    end
  end

  describe '#with' do
    it 'creates a copy with overrides' do
      config = described_class.new
      new_config = config.with(min_cells: 6, min_rows: 3)

      expect(new_config.min_cells).to eq(6)
      expect(new_config.min_rows).to eq(3)
      # Original unchanged
      expect(config.min_cells).to eq(4)
      expect(config.min_rows).to eq(2)
    end
  end
end

RSpec.describe Tabula do
  describe '.configuration' do
    it 'returns the default configuration' do
      config = described_class.configuration
      expect(config).to be_a(Tabula::Configuration)
    end

    it 'returns the same instance each time' do
      expect(described_class.configuration).to be(described_class.configuration)
    end
  end

  describe '.configure' do
    it 'yields the configuration' do
      described_class.configure do |config|
        expect(config).to be_a(Tabula::Configuration)
      end
    end

    it 'allows modifying configuration' do
      original_tolerance = described_class.configuration.orientation_tolerance

      described_class.configure do |config|
        config.orientation_tolerance = 2.0
      end

      expect(described_class.configuration.orientation_tolerance).to eq(2.0)

      # Reset for other tests
      described_class.configuration.orientation_tolerance = original_tolerance
    end
  end
end
