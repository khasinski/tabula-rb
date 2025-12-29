# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024

Initial release of tabula-rb, a Ruby port of tabula-java.

### Added

- **Table Extraction**: Extract tables from PDF files using two modes:
  - Lattice mode: For PDFs with visible ruling lines/borders
  - Stream mode: For PDFs without visible borders (uses text positioning)
  - Auto mode: Tries lattice first, falls back to stream

- **Output Formats**:
  - CSV (with customizable separator and quoting)
  - TSV
  - JSON (with optional pretty-printing and metadata)
  - Markdown (GitHub-flavored, with alignment options)

- **Command Line Interface**:
  - Extract tables from multiple PDF files
  - Page selection (individual pages, ranges, or all)
  - Area extraction (specify top, left, bottom, right coordinates)
  - Column boundary specification
  - Auto-detection of table areas (`--guess`)
  - Password-protected PDF support

- **Text Handling**:
  - Proper UTF-8 encoding support
  - Right-to-left (RTL) text support (Arabic, Hebrew, etc.)
  - Merged text runs for proper word/phrase extraction

- **PDF Features**:
  - Support for rotated pages
  - Password-protected PDF support
  - Ruling line detection from PDF graphics stream

- **Core Geometry**:
  - Rectangle, Point, and Ruling primitives
  - Spatial indexing for efficient text lookup
  - Cohen-Sutherland line clipping algorithm
  - Projection profile analysis

- **Detection Algorithms**:
  - Spreadsheet detection (ruling-based)
  - Nurminen detection algorithm for table area detection

- **Configuration**:
  - Customizable tolerance thresholds for text merging
  - Configurable cell detection parameters

### Known Limitations

- Percentage-based area specification in CLI is parsed but not fully implemented
- Spanning cell extraction works but may need refinement for complex layouts
- Some PDFs without drawn ruling lines require stream mode (this is expected behavior)
