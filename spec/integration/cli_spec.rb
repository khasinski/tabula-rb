# frozen_string_literal: true

require "open3"

RSpec.describe "CLI" do
  let(:cli_path) { File.expand_path("../../exe/tabula", __dir__) }
  let(:bundle_cmd) { "mise exec ruby -- bundle exec ruby" }

  describe "basic usage" do
    it "shows help with --help" do
      stdout, _stderr, status = Open3.capture3("#{bundle_cmd} #{cli_path} --help")

      expect(status.success?).to be true
      expect(stdout).to include("Usage:")
      expect(stdout).to include("--format")
    end

    it "shows version with --version" do
      stdout, _stderr, status = Open3.capture3("#{bundle_cmd} #{cli_path} --version")

      expect(status.success?).to be true
      expect(stdout).to include(Tabula::VERSION)
    end
  end

  describe "extraction" do
    it "extracts from PDF file" do
      pdf_path = fixture_pdf("us-017")
      stdout, _stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -l -p 2 #{pdf_path}"
      )

      expect(status.success?).to be true
      # Should output CSV data
      expect(stdout).not_to be_empty
    end

    it "extracts with lattice mode" do
      pdf_path = fixture_pdf("us-017")
      _stdout, _stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -l -p 2 #{pdf_path}"
      )

      expect(status.success?).to be true
    end

    it "extracts with stream mode" do
      pdf_path = fixture_pdf("us-017")
      _stdout, _stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -t -p 2 #{pdf_path}"
      )

      expect(status.success?).to be true
    end

    it "outputs JSON format" do
      pdf_path = fixture_pdf("us-017")
      stdout, stderr, status = Open3.capture3(
        "mise exec ruby -- bundle exec ruby #{cli_path} -f JSON -p 2 -l #{pdf_path}"
      )

      expect(status.success?).to be(true), "Failed with: #{stderr}"
      # Should be valid JSON
      if stdout.strip.length > 0
        expect { JSON.parse(stdout) }.not_to raise_error
      end
    end

    it "outputs TSV format" do
      pdf_path = fixture_pdf("us-017")
      _stdout, _stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -f TSV -l -p 2 #{pdf_path}"
      )

      expect(status.success?).to be true
    end
  end

  describe "error handling" do
    it "fails with missing file" do
      _stdout, stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} nonexistent.pdf"
      )

      expect(status.success?).to be false
      expect(stderr).to include("not found").or include("File not found")
    end

    it "requires PDF file argument" do
      _stdout, _stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path}"
      )

      expect(status.success?).to be false
    end

    it "provides helpful message for file not found" do
      _stdout, stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} nonexistent.pdf"
      )

      expect(status.success?).to be false
      expect(stderr).to include("Please check that the file path is correct")
    end

    it "fails with invalid page range" do
      pdf_path = fixture_pdf("us-017")
      _stdout, stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -p 5-2 #{pdf_path}"
      )

      expect(status.success?).to be false
      expect(stderr).to include("Invalid page range")
    end

    it "fails with non-numeric page" do
      pdf_path = fixture_pdf("us-017")
      _stdout, stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -p abc #{pdf_path}"
      )

      expect(status.success?).to be false
      expect(stderr).to include("Invalid page number")
    end

    it "fails with invalid area format" do
      pdf_path = fixture_pdf("us-017")
      _stdout, stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -a 10,20,30 #{pdf_path}"
      )

      expect(status.success?).to be false
      expect(stderr).to include("Area must have 4 values")
    end

    it "fails with non-numeric area values" do
      pdf_path = fixture_pdf("us-017")
      _stdout, stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -a 10,abc,30,40 #{pdf_path}"
      )

      expect(status.success?).to be false
      expect(stderr).to include("must be numeric")
    end

    it "shows helpful hint for invalid options" do
      pdf_path = fixture_pdf("us-017")
      _stdout, stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -p abc #{pdf_path}"
      )

      expect(status.success?).to be false
      expect(stderr).to include("Use --help")
    end
  end

  describe "page selection" do
    it "extracts specific pages" do
      pdf_path = fixture_pdf("S2MNCEbirdisland")
      _stdout, _stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -p 1,2 #{pdf_path}"
      )

      expect(status.success?).to be true
    end

    it "extracts page range" do
      pdf_path = fixture_pdf("S2MNCEbirdisland")
      _stdout, _stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -p 1-2 #{pdf_path}"
      )

      expect(status.success?).to be true
    end

    it "extracts all pages" do
      pdf_path = fixture_pdf("S2MNCEbirdisland")
      _stdout, _stderr, status = Open3.capture3(
        "#{bundle_cmd} #{cli_path} -p all #{pdf_path}"
      )

      expect(status.success?).to be true
    end
  end
end
