# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2024

### Fixed

- Fixed extraction of spanning row labels in lattice mode. Tables with cells spanning multiple rows (where horizontal rulings don't extend across all columns) now correctly extract text labels like "Servo motor type", "Compatible servo drive unit type", etc.
- Improved column-by-column cell detection algorithm to handle partial horizontal rulings that only cover certain columns
- Filtered out short/noise rulings (< 20 points) that were creating spurious column boundaries
- Now extracts additional data columns that tabula-java misses in some PDFs

## [1.0.2] - 2024

### Fixed

- Fixed extraction of leftmost column in tables where horizontal rulings extend beyond vertical rulings. Tables with no left border now correctly include the leftmost column data.

## [1.0.1] - 2024

### Fixed

- Fixed gem build warnings about file permissions
- Removed duplicate homepage_uri metadata in gemspec

## [1.0.0] - 2024

Initial stable release of tabula-rb, a pure Ruby port of tabula-java.

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

### Notes

- PDFs without drawn ruling lines require stream mode (lattice mode needs visible cell borders)
