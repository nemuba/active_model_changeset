# frozen_string_literal: true

require "rails/railtie"

module ActiveModelChangeset
  class Railtie < Rails::Railtie
    initializer "active_model_changeset.require" do
      # Nada a fazer; manter vazio evita efeitos colaterais
    end
  end
end
