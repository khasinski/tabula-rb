# frozen_string_literal: true

require_relative "lib/tabula/version"

Gem::Specification.new do |spec|
  spec.name = "tabula"
  spec.version = Tabula::VERSION
  spec.authors = ["Chris Hasiński"]
  spec.email = ["krzysztof.hasinski@gmail.com"]

  spec.summary = "Extract tables from PDF files"
  spec.description = <<~DESC
    Tabula is a library for extracting tables from PDF files. It supports both
    lattice-mode extraction (for PDFs with ruling lines) and stream-mode extraction
    (for PDFs without ruling lines). Ruby port of tabula-java.
  DESC
  spec.homepage = "https://github.com/tabulapdf/tabula-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "pdf-reader", "~> 2.0"
  spec.add_dependency "csv", "~> 3.0"

  # Optional dependencies for advanced features
  # spec.add_dependency "mini_magick", "~> 4.0"  # For Nurminen detection

  spec.metadata["rubygems_mfa_required"] = "true"
end
