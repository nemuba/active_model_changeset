# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in active_model_changeset.gemspec
gemspec

gem "irb"
gem "rake", "~> 13.0"

group :development, :test do
  gem "rspec", "~> 3.0"
  gem "rubocop", "~> 1.21"
  gem "rubocop-rake", "~> 0.6"
  gem "rubocop-rspec", "~> 2.5"

  # Cobertura de código
  gem "simplecov", "~> 0.22", require: false

  # Dados de teste
  gem "faker", "~> 3.0"

  # Documentação
  gem "webrick", "~> 1.8" # Servidor para yard server
  gem "yard", "~> 0.9"
end
