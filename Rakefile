# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

# YARD Documentation
begin
  require "yard"

  YARD::Rake::YardocTask.new do |t|
    t.files = ["lib/**/*.rb"]
    t.options = ["--output-dir", "doc", "--readme", "README.md"]
  end
rescue LoadError
  desc "YARD não disponível"
  task :yard do
    puts "YARD não está instalado. Execute: bundle install"
  end
end

task default: %i[spec rubocop]
