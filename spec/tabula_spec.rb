# frozen_string_literal: true

RSpec.describe Tabula do
  describe "custom exceptions" do
    it "defines FileNotFoundError as a subclass of Tabula::Error" do
      expect(Tabula::FileNotFoundError).to be < Tabula::Error
    end

    it "defines InvalidOptionsError as a subclass of Tabula::Error" do
      expect(Tabula::InvalidOptionsError).to be < Tabula::Error
    end
  end

  describe ".extract" do
    describe "file validation" do
      it "raises FileNotFoundError when file does not exist" do
        expect {
          Tabula.extract("/nonexistent/path/to/file.pdf")
        }.to raise_error(Tabula::FileNotFoundError, /File not found/)
      end

      it "includes the file path in the error message" do
        path = "/nonexistent/path/to/file.pdf"
        expect {
          Tabula.extract(path)
        }.to raise_error(Tabula::FileNotFoundError, /#{Regexp.escape(path)}/)
      end
    end

    describe "pages validation" do
      let(:valid_pdf) { fixture_pdf("us-017") }

      it "raises InvalidOptionsError when pages is not an array" do
        expect {
          Tabula.extract(valid_pdf, pages: "1,2,3")
        }.to raise_error(Tabula::InvalidOptionsError, /Pages must be an array/)
      end

      it "raises InvalidOptionsError when pages contains non-integers" do
        expect {
          Tabula.extract(valid_pdf, pages: [1, "2", 3])
        }.to raise_error(Tabula::InvalidOptionsError, /Page numbers must be positive integers/)
      end

      it "raises InvalidOptionsError when pages contains floats" do
        expect {
          Tabula.extract(valid_pdf, pages: [1.5, 2])
        }.to raise_error(Tabula::InvalidOptionsError, /Page numbers must be positive integers/)
      end

      it "raises InvalidOptionsError when pages contains zero" do
        expect {
          Tabula.extract(valid_pdf, pages: [0, 1, 2])
        }.to raise_error(Tabula::InvalidOptionsError, /Page numbers must be positive integers/)
      end

      it "raises InvalidOptionsError when pages contains negative numbers" do
        expect {
          Tabula.extract(valid_pdf, pages: [-1, 1, 2])
        }.to raise_error(Tabula::InvalidOptionsError, /Page numbers must be positive integers/)
      end

      it "accepts valid pages array with positive integers" do
        # Should not raise an error for valid pages
        expect {
          Tabula.extract(valid_pdf, pages: [1, 2])
        }.not_to raise_error
      end
    end

    describe "area validation" do
      let(:valid_pdf) { fixture_pdf("us-017") }

      it "raises InvalidOptionsError when area has fewer than 4 values" do
        expect {
          Tabula.extract(valid_pdf, area: [10, 20, 30])
        }.to raise_error(Tabula::InvalidOptionsError, /Area must be an array of exactly 4 values/)
      end

      it "raises InvalidOptionsError when area has more than 4 values" do
        expect {
          Tabula.extract(valid_pdf, area: [10, 20, 30, 40, 50])
        }.to raise_error(Tabula::InvalidOptionsError, /Area must be an array of exactly 4 values/)
      end

      it "raises InvalidOptionsError when area is not an array" do
        expect {
          Tabula.extract(valid_pdf, area: "10,20,30,40")
        }.to raise_error(Tabula::InvalidOptionsError, /Area must be an array of exactly 4 values/)
      end

      it "raises InvalidOptionsError when area contains non-numeric values" do
        expect {
          Tabula.extract(valid_pdf, area: [10, "20", 30, 40])
        }.to raise_error(Tabula::InvalidOptionsError, /Area left must be numeric/)
      end

      it "raises InvalidOptionsError for non-numeric top value" do
        expect {
          Tabula.extract(valid_pdf, area: ["bad", 20, 30, 40])
        }.to raise_error(Tabula::InvalidOptionsError, /Area top must be numeric/)
      end

      it "raises InvalidOptionsError for non-numeric bottom value" do
        expect {
          Tabula.extract(valid_pdf, area: [10, 20, nil, 40])
        }.to raise_error(Tabula::InvalidOptionsError, /Area bottom must be numeric/)
      end

      it "raises InvalidOptionsError for non-numeric right value" do
        expect {
          Tabula.extract(valid_pdf, area: [10, 20, 30, {}])
        }.to raise_error(Tabula::InvalidOptionsError, /Area right must be numeric/)
      end

      it "accepts valid area with integers" do
        expect {
          Tabula.extract(valid_pdf, pages: [2], area: [10, 20, 300, 400])
        }.not_to raise_error
      end

      it "accepts valid area with floats" do
        expect {
          Tabula.extract(valid_pdf, pages: [2], area: [10.5, 20.5, 300.5, 400.5])
        }.not_to raise_error
      end
    end

    describe "method validation" do
      let(:valid_pdf) { fixture_pdf("us-017") }

      it "raises InvalidOptionsError for invalid method symbol" do
        expect {
          Tabula.extract(valid_pdf, method: :invalid)
        }.to raise_error(Tabula::InvalidOptionsError, /Method must be one of/)
      end

      it "raises InvalidOptionsError for string method" do
        expect {
          Tabula.extract(valid_pdf, method: "lattice")
        }.to raise_error(Tabula::InvalidOptionsError, /Method must be one of/)
      end

      it "accepts :lattice method" do
        expect {
          Tabula.extract(valid_pdf, pages: [2], method: :lattice)
        }.not_to raise_error
      end

      it "accepts :stream method" do
        expect {
          Tabula.extract(valid_pdf, pages: [2], method: :stream)
        }.not_to raise_error
      end

      it "accepts :auto method" do
        expect {
          Tabula.extract(valid_pdf, pages: [2], method: :auto)
        }.not_to raise_error
      end
    end

    describe "combined validations" do
      let(:valid_pdf) { fixture_pdf("us-017") }

      it "validates file first before other options" do
        # File validation should happen before pages validation
        expect {
          Tabula.extract("/nonexistent.pdf", pages: "invalid")
        }.to raise_error(Tabula::FileNotFoundError)
      end

      it "validates all options when file exists" do
        expect {
          Tabula.extract(valid_pdf, pages: [1], area: [10, 20, 30], method: :lattice)
        }.to raise_error(Tabula::InvalidOptionsError, /Area must be an array of exactly 4 values/)
      end
    end
  end

  describe "VALID_METHODS constant" do
    it "contains :lattice, :stream, and :auto" do
      expect(Tabula::VALID_METHODS).to contain_exactly(:lattice, :stream, :auto)
    end

    it "is frozen" do
      expect(Tabula::VALID_METHODS).to be_frozen
    end
  end
end
