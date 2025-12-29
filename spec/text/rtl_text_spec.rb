# frozen_string_literal: true

RSpec.describe 'RTL Text Handling' do
  describe Tabula::TextElement do
    describe 'direction detection' do
      it 'detects LTR text' do
        element = described_class.new(
          top: 0, left: 0, width: 10, height: 10,
          text: 'A', direction: Tabula::TextElement::DIRECTION_LTR
        )
        expect(element.ltr?).to be true
        expect(element.rtl?).to be false
      end

      it 'detects RTL text' do
        element = described_class.new(
          top: 0, left: 0, width: 10, height: 10,
          text: "\u0627", # Arabic alef
          direction: Tabula::TextElement::DIRECTION_RTL
        )
        expect(element.ltr?).to be false
        expect(element.rtl?).to be true
      end
    end
  end

  describe Tabula::TextChunk do
    describe '#ltr_dominant?' do
      it 'returns true for LTR elements' do
        element1 = Tabula::TextElement.new(top: 0, left: 0, width: 10, height: 10, text: 'A')
        chunk = described_class.new(element1)
        chunk.add(Tabula::TextElement.new(top: 0, left: 10, width: 10, height: 10, text: 'B'))

        expect(chunk.ltr_dominant?).to be true
      end

      it 'returns false for RTL elements' do
        element1 = Tabula::TextElement.new(
          top: 0, left: 0, width: 10, height: 10,
          text: "\u0627",
          direction: Tabula::TextElement::DIRECTION_RTL
        )
        chunk = described_class.new(element1)
        chunk.add(Tabula::TextElement.new(
                    top: 0, left: 10, width: 10, height: 10,
                    text: "\u0628",
                    direction: Tabula::TextElement::DIRECTION_RTL
                  ))

        expect(chunk.ltr_dominant?).to be false
        expect(chunk.rtl_dominant?).to be true
      end
    end

    describe '#text' do
      it 'assembles LTR text left-to-right' do
        element1 = Tabula::TextElement.new(top: 0, left: 0, width: 10, height: 10, text: 'A')
        chunk = described_class.new(element1)
        chunk.add(Tabula::TextElement.new(top: 0, left: 10, width: 10, height: 10, text: 'B'))
        chunk.add(Tabula::TextElement.new(top: 0, left: 20, width: 10, height: 10, text: 'C'))

        expect(chunk.text).to eq('ABC')
      end

      it 'assembles RTL text right-to-left' do
        # RTL elements are still stored by their physical position (left coordinate)
        # but text assembly should reverse them
        element1 = Tabula::TextElement.new(
          top: 0, left: 20, width: 10, height: 10,
          text: "\u0627", # alef - rightmost visually, but first logically
          direction: Tabula::TextElement::DIRECTION_RTL
        )
        chunk = described_class.new(element1)
        chunk.add(Tabula::TextElement.new(
                    top: 0, left: 10, width: 10, height: 10,
                    text: "\u0628", # ba - middle
                    direction: Tabula::TextElement::DIRECTION_RTL
                  ))
        chunk.add(Tabula::TextElement.new(
                    top: 0, left: 0, width: 10, height: 10,
                    text: "\u062A", # ta - leftmost visually, but last logically
                    direction: Tabula::TextElement::DIRECTION_RTL
                  ))

        # For RTL, elements are sorted by left descending, so rightmost comes first
        expect(chunk.text).to eq("\u0627\u0628\u062A")
      end
    end
  end

  describe Tabula::Line do
    describe '#ltr_dominant?' do
      it 'returns true for empty lines' do
        line = described_class.new
        expect(line.ltr_dominant?).to be true
      end

      it 'returns true for LTR chunks' do
        line = described_class.new
        element = Tabula::TextElement.new(top: 0, left: 0, width: 10, height: 10, text: 'Hello')
        chunk = Tabula::TextChunk.new(element)
        line.add_chunk(chunk)

        expect(line.ltr_dominant?).to be true
      end

      it 'returns false for RTL chunks' do
        line = described_class.new
        element = Tabula::TextElement.new(
          top: 0, left: 0, width: 10, height: 10,
          text: "\u0645\u0631\u062D\u0628\u0627", # marhaba
          direction: Tabula::TextElement::DIRECTION_RTL
        )
        chunk = Tabula::TextChunk.new(element)
        line.add_chunk(chunk)

        expect(line.rtl_dominant?).to be true
      end
    end

    describe '#sorted_chunks' do
      it 'sorts LTR chunks left-to-right' do
        line = described_class.new

        element1 = Tabula::TextElement.new(top: 0, left: 0, width: 10, height: 10, text: 'First')
        chunk1 = Tabula::TextChunk.new(element1)
        line.add_chunk(chunk1)

        element2 = Tabula::TextElement.new(top: 0, left: 50, width: 10, height: 10, text: 'Second')
        chunk2 = Tabula::TextChunk.new(element2)
        line.add_chunk(chunk2)

        sorted = line.sorted_chunks
        expect(sorted.first.text).to eq('First')
        expect(sorted.last.text).to eq('Second')
      end

      it 'sorts RTL chunks right-to-left' do
        line = described_class.new

        # chunk1 is at the right side (left=50)
        # Use TextChunk.new with element directly to set proper bounds
        element1 = Tabula::TextElement.new(
          top: 0, left: 50, width: 10, height: 10,
          text: "\u0623\u0648\u0644", # awwal (first in Arabic)
          direction: Tabula::TextElement::DIRECTION_RTL
        )
        chunk1 = Tabula::TextChunk.new(element1)
        line.add_chunk(chunk1)

        # chunk2 is at the left side (left=0)
        element2 = Tabula::TextElement.new(
          top: 0, left: 0, width: 10, height: 10,
          text: "\u062B\u0627\u0646\u064A", # thani (second in Arabic)
          direction: Tabula::TextElement::DIRECTION_RTL
        )
        chunk2 = Tabula::TextChunk.new(element2)
        line.add_chunk(chunk2)

        # Verify line is RTL dominant
        expect(line.rtl_dominant?).to be true

        sorted = line.sorted_chunks
        # RTL: rightmost chunk (chunk1 at left=50) should come first
        expect(sorted.size).to eq(2)
        expect(sorted[0].left).to eq(50.0)
        expect(sorted[1].left).to eq(0.0)
      end
    end
  end

  describe Tabula::TextStripper do
    describe '#rtl_text?' do
      let(:page) { instance_double(PDF::Reader::Page) }
      let(:stripper) { described_class.new(page) }

      it 'detects Arabic text' do
        expect(stripper.send(:rtl_text?, "\u0627\u0644\u0639\u0631\u0628\u064A\u0629")).to be true
      end

      it 'detects Hebrew text' do
        expect(stripper.send(:rtl_text?, "\u05E9\u05DC\u05D5\u05DD")).to be true
      end

      it 'returns false for Latin text' do
        expect(stripper.send(:rtl_text?, 'Hello')).to be false
      end

      it 'returns false for nil' do
        expect(stripper.send(:rtl_text?, nil)).to be false
      end

      it 'returns false for empty string' do
        expect(stripper.send(:rtl_text?, '')).to be false
      end

      it 'detects Syriac text' do
        expect(stripper.send(:rtl_text?, "\u0710\u0712")).to be true
      end

      it 'detects Thaana text' do
        expect(stripper.send(:rtl_text?, "\u0780\u0781")).to be true
      end

      it "detects N'Ko text" do
        expect(stripper.send(:rtl_text?, "\u07C0\u07C1")).to be true
      end
    end
  end
end
