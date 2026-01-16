# frozen_string_literal: true

# SimpleCov deve ser carregado ANTES de qualquer código da aplicação
require "simplecov"

SimpleCov.start do
  # Configuração de cobertura mínima
  minimum_coverage 90

  # Adiciona grupos para organizar a cobertura
  add_group "Lib", "lib"
  add_group "Specs", "spec"

  # Ignora arquivos de teste e configuração
  add_filter "/spec/"
  add_filter "/vendor/"

  # Habilita tracking de branches (Ruby 2.5+)
  enable_coverage :branch

  # Formatters
  formatter SimpleCov::Formatter::HTMLFormatter
end

require "active_model_changeset"
require "faker"

# Carrega arquivos de suporte
Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Ordem aleatória para detectar dependências entre testes
  config.order = :random

  # Seed para reproduzir a ordem
  Kernel.srand config.seed
end
