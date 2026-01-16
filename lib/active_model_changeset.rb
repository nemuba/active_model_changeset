# frozen_string_literal: true

require "active_support"
require "active_model"
require_relative "active_model_changeset/version"
require_relative "active_model_changeset/base"

# Railtie opcional: só carregue se estiver em Rails
begin
  require_relative "active_model_changeset/railtie"
rescue LoadError
  # sem Rails, ok
end

module ActiveModelChangeset
  # Alias para retrocompatibilidade
  # @deprecated Use {ActiveModelChangeset::Base} ao invés
  Changeset = Base
end
