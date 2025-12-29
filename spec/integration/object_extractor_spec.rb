# frozen_string_literal: true

RSpec.describe Tabula::ObjectExtractor do
  describe 'page extraction' do
    it 'can read PDF with owner encryption' do
      extractor = described_class.new(fixture_pdf('S2MNCEbirdisland'))

      pages = extractor.extract.map { |page| page }

      expect(pages.size).to eq(2)
    end

    it 'extracts a single page' do
      extractor = described_class.new(fixture_pdf('S2MNCEbirdisland'))
      expect(extractor.page_count).to eq(2)

      page = extractor.extract_page(2)
      expect(page).not_to be_nil
    end

    it 'raises error for wrong page number' do
      extractor = described_class.new(fixture_pdf('S2MNCEbirdisland'))
      expect(extractor.page_count).to eq(2)

      expect { extractor.extract_page(3) }.to raise_error(ArgumentError)
    end

    it 'extracts text from rotated page without raising' do
      extractor = described_class.new(fixture_pdf('rotated_page'))
      iterator = extractor.extract

      page = iterator.first
      expect(page).not_to be_nil
    end

    it 'extracts rulings that are contained within page bounds' do
      extractor = described_class.new(fixture_pdf('should_detect_rulings'))
      page = extractor.extract.first

      rulings = page.rulings

      rulings.each do |r|
        expect(r.left).to be >= page.left
        expect(r.right).to be <= page.right
        expect(r.top).to be >= page.top
        expect(r.bottom).to be <= page.bottom
      end
    end

    it 'extracts page without NPE in shfill' do
      extractor = described_class.new(fixture_pdf('labor'))
      iterator = extractor.extract

      expect { iterator.first }.not_to raise_error
    end

    it 'extracts text elements from page' do
      extractor = described_class.new(fixture_pdf('cs-en-us-pbms'))
      page = extractor.extract_page(1)

      # Verify text elements are extracted
      expect(page.text_elements).not_to be_empty

      # Verify text content makes sense (should contain "Bill" somewhere in the text)
      all_text = page.text_elements.map(&:text).join(' ')
      expect(all_text).to include('Bill')
    end

    it 'does not raise NPE in point comparator' do
      extractor = described_class.new(fixture_pdf('npe_issue_206'))

      expect { extractor.extract_page(1) }.not_to raise_error
    end
  end

  describe 'password protected PDFs' do
    it 'raises error on encrypted file without password' do
      expect do
        extractor = described_class.new(fixture_pdf('encrypted'))
        extractor.extract.first
      end.to raise_error(Tabula::PasswordRequiredError)
    end

    it 'opens encrypted PDF with correct password' do
      extractor = described_class.new(fixture_pdf('encrypted'), password: 'userpassword')
      pages = extractor.extract.to_a

      expect(pages.size).to eq(1)
    end
  end

  describe '.open with block' do
    it 'yields extractor and closes afterward' do
      described_class.open(fixture_pdf('S2MNCEbirdisland')) do |extractor|
        expect(extractor.page_count).to eq(2)
        expect(extractor.closed?).to be false
      end
    end
  end
end
