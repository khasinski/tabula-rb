# frozen_string_literal: true

require "optparse"

module Tabula
  # Command-line interface for tabula
  class CLI
    FORMATS = %w[CSV TSV JSON].freeze

    def self.run(args)
      new.run(args)
    end

    def initialize
      @options = default_options
    end

    def run(args)
      parser = build_parser
      files = parser.parse(args)

      if @options[:help]
        puts parser
        return 0
      end

      if @options[:version]
        puts "tabula #{Tabula::VERSION}"
        return 0
      end

      if files.empty?
        warn "Error: No PDF file specified"
        warn parser
        return 1
      end

      process_files(files)
    rescue OptionParser::InvalidOption => e
      warn "Error: #{e.message}"
      warn parser
      1
    rescue StandardError => e
      warn "Error: #{e.message}"
      warn e.backtrace.first(5).join("\n") if @options[:debug]
      1
    end

    private

    def default_options
      {
        area: nil,
        columns: nil,
        format: "CSV",
        guess: false,
        lattice: false,
        stream: false,
        pages: nil,
        output: nil,
        password: nil,
        help: false,
        version: false,
        debug: false
      }
    end

    def build_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: tabula [OPTIONS] <pdf_file> [<pdf_file> ...]"
        opts.separator ""
        opts.separator "Extract tables from PDF files"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-a", "--area AREA", "Extraction area (top,left,bottom,right or %)") do |v|
          @options[:area] = parse_area(v)
        end

        opts.on("-c", "--columns COLUMNS", "Column boundaries (comma-separated x coordinates)") do |v|
          @options[:columns] = v.split(",").map(&:to_f)
        end

        opts.on("-f", "--format FORMAT", FORMATS, "Output format: #{FORMATS.join(', ')} (default: CSV)") do |v|
          @options[:format] = v.upcase
        end

        opts.on("-g", "--guess", "Guess table areas (use detection algorithm)") do
          @options[:guess] = true
        end

        opts.on("-l", "--lattice", "Force lattice mode (use ruling lines)") do
          @options[:lattice] = true
          @options[:stream] = false
        end

        opts.on("-t", "--stream", "Force stream mode (use text positions)") do
          @options[:stream] = true
          @options[:lattice] = false
        end

        opts.on("-p", "--pages PAGES", "Pages to extract (e.g., '1,2,3' or '1-5' or 'all')") do |v|
          @options[:pages] = parse_pages(v)
        end

        opts.on("-o", "--output FILE", "Output file (default: stdout)") do |v|
          @options[:output] = v
        end

        opts.on("-s", "--password PASSWORD", "PDF password") do |v|
          @options[:password] = v
        end

        opts.on("--debug", "Show debug information") do
          @options[:debug] = true
        end

        opts.on("-v", "--version", "Show version") do
          @options[:version] = true
        end

        opts.on("-h", "--help", "Show this help") do
          @options[:help] = true
        end
      end
    end

    def parse_area(value)
      parts = value.split(",").map(&:strip)
      unless parts.size == 4
        raise ArgumentError, "Area must have 4 values: top,left,bottom,right"
      end

      parts.map do |p|
        if p.end_with?("%")
          { percent: p.to_f }
        else
          p.to_f
        end
      end
    end

    def parse_pages(value)
      return nil if value.downcase == "all"

      pages = []
      value.split(",").each do |part|
        part = part.strip
        if part.include?("-")
          range = part.split("-").map(&:to_i)
          pages.concat((range[0]..range[1]).to_a)
        else
          pages << part.to_i
        end
      end
      pages.uniq.sort
    end

    def process_files(files)
      output_io = @options[:output] ? File.open(@options[:output], "w") : $stdout

      begin
        files.each_with_index do |file, idx|
          output_io.puts if idx.positive? # Separate multiple files

          unless File.exist?(file)
            warn "Warning: File not found: #{file}"
            next
          end

          process_file(file, output_io)
        end
      ensure
        output_io.close if @options[:output]
      end

      0
    end

    def process_file(file, output_io)
      extraction_options = build_extraction_options

      tables = Tabula.extract(file, **extraction_options)

      if tables.empty?
        warn "No tables found in #{file}" if @options[:debug]
        return
      end

      write_tables(tables, output_io)
    end

    def build_extraction_options
      options = {
        password: @options[:password],
        guess: @options[:guess]
      }

      # Set extraction method
      if @options[:lattice]
        options[:method] = :lattice
      elsif @options[:stream]
        options[:method] = :stream
      else
        options[:method] = :auto
      end

      # Set pages
      options[:pages] = @options[:pages] if @options[:pages]

      # Set area
      if @options[:area]
        options[:area] = resolve_area(@options[:area])
      end

      # Set columns
      options[:columns] = @options[:columns] if @options[:columns]

      options
    end

    def resolve_area(area)
      # If any values are percentages, we'd need page dimensions
      # For now, just treat them as absolute values
      area.map do |v|
        v.is_a?(Hash) ? v[:percent] : v
      end
    end

    def write_tables(tables, output_io)
      case @options[:format]
      when "CSV"
        Writers::CSVWriter.new.write(tables, output_io)
      when "TSV"
        Writers::TSVWriter.new.write(tables, output_io)
      when "JSON"
        Writers::JSONWriter.new(pretty: true).write(tables, output_io)
      end
    end
  end
end
