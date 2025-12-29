# Tabula

A Ruby library for extracting tables from PDF files.

This is a pure Ruby port of [tabula-java](https://github.com/tabulapdf/tabula-java), the open-source library that powers [Tabula](https://tabula.technology/). It implements the same extraction algorithms and produces compatible output, allowing you to extract tables from PDFs without requiring Java or JRuby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tabula'
```

And then execute:

```bash
bundle install
```

Or install it directly:

```bash
gem install tabula
```

## Usage

### Library

```ruby
require 'tabula'

# Extract all tables from a PDF
tables = Tabula.extract("document.pdf")

# Each table can be converted to different formats
tables.each do |table|
  puts table.to_a.inspect    # Array of arrays
  puts table.to_csv          # CSV string
end

# Extract from specific pages
tables = Tabula.extract("document.pdf", pages: [1, 2, 3])

# Use lattice mode (for PDFs with ruling lines/borders)
tables = Tabula.extract("document.pdf", method: :lattice)

# Use stream mode (for PDFs without ruling lines)
tables = Tabula.extract("document.pdf", method: :stream)

# Extract a specific area (top, left, bottom, right in points)
tables = Tabula.extract("document.pdf", area: [0, 0, 500, 800])

# Auto-detect table areas
tables = Tabula.extract("document.pdf", guess: true)

# Password-protected PDFs
tables = Tabula.extract("document.pdf", password: "secret")
```

### Output Formats

```ruby
tables = Tabula.extract("document.pdf")

# CSV
Tabula::Writers::CSVWriter.to_string(tables)

# TSV
Tabula::Writers::TSVWriter.to_string(tables)

# JSON
Tabula::Writers::JSONWriter.to_string(tables)
Tabula::Writers::JSONWriter.to_string(tables, pretty: true)

# Markdown
Tabula::Writers::MarkdownWriter.to_string(tables)
Tabula::Writers::MarkdownWriter.to_string(tables, alignment: :center)
```

### Command Line

```bash
# Basic extraction (outputs CSV to stdout)
tabula document.pdf

# Specify output format
tabula -f CSV document.pdf
tabula -f TSV document.pdf
tabula -f JSON document.pdf
tabula -f MARKDOWN document.pdf

# Write to file
tabula -o output.csv document.pdf

# Extract specific pages
tabula -p 1,2,3 document.pdf
tabula -p 1-5 document.pdf
tabula -p all document.pdf

# Force extraction mode
tabula -l document.pdf  # Lattice mode (ruling lines)
tabula -t document.pdf  # Stream mode (text positions)

# Extract specific area
tabula -a 0,0,500,800 document.pdf

# Auto-detect table areas
tabula -g document.pdf

# Password-protected PDF
tabula -s mypassword document.pdf
```

Full CLI options:

```
Usage: tabula [OPTIONS] <pdf_file> [<pdf_file> ...]

Options:
    -a, --area AREA          Extraction area (top,left,bottom,right)
    -c, --columns COLUMNS    Column boundaries (comma-separated x coordinates)
    -f, --format FORMAT      Output format: CSV, TSV, JSON, MARKDOWN (default: CSV)
    -g, --guess              Guess table areas (use detection algorithm)
    -l, --lattice            Force lattice mode (use ruling lines)
    -t, --stream             Force stream mode (use text positions)
    -p, --pages PAGES        Pages to extract (e.g., '1,2,3' or '1-5' or 'all')
    -o, --output FILE        Output file (default: stdout)
    -s, --password PASSWORD  PDF password
        --debug              Show debug information
    -v, --version            Show version
    -h, --help               Show this help
```

## Extraction Modes

### Lattice Mode (`-l` / `:lattice`)

Best for tables with visible borders/ruling lines. The algorithm detects cell boundaries by finding intersections of horizontal and vertical lines drawn in the PDF.

### Stream Mode (`-t` / `:stream`)

Best for tables without visible borders. The algorithm infers table structure from text positioning, looking for gaps between text elements to determine column boundaries.

### Auto Mode (default)

Tries lattice mode first. If no tables are found, falls back to stream mode.

## Requirements

- Ruby 3.1+
- pdf-reader gem (automatically installed as dependency)

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rspec
```

## License

MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

This gem is a Ruby port of [tabula-java](https://github.com/tabulapdf/tabula-java) by the [Tabula](https://tabula.technology/) team. The extraction algorithms, test fixtures, and expected behaviors are derived from the original Java implementation.

Special thanks to:
- [Manuel Aristarán](https://github.com/jazzido) and the Tabula team for creating the original tabula-java
- The [pdf-reader](https://github.com/yob/pdf-reader) gem maintainers for the excellent PDF parsing library
