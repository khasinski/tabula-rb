# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :spec do
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/{core,text,table,pdf,extractors,detectors,writers,algorithms}/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
  end
end

namespace :doc do
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb']
    t.options = ['--output-dir', 'doc']
  end
end
