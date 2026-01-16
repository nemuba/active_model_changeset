# frozen_string_literal: true

# UserChangeset para testes com normalização e validação
class UserChangeset < ActiveModelChangeset::Base
  attribute :name, :string, normalize: %i[strip squish]
  attribute :email, :string, normalize: %i[strip downcase]
  attribute :age, :integer
  attribute :bio, :string, normalize: :blank_to_nil

  validates :name, presence: true
  validates :email, presence: true
  validates :age, numericality: { greater_than: 0 }, allow_nil: true
end

# SimpleChangeset sem validações para testes básicos
class SimpleChangeset < ActiveModelChangeset::Base
  attribute :name, :string
  attribute :value, :integer
end

# ChangesetWithModel para testar o método .model
class ChangesetWithModel < ActiveModelChangeset::Base
  model MockRecord

  attribute :name, :string
end

# ChangesetWithAllNormalizers para testar todos os normalizadores
class ChangesetWithAllNormalizers < ActiveModelChangeset::Base
  attribute :strip_field, :string, normalize: :strip
  attribute :squish_field, :string, normalize: :squish
  attribute :downcase_field, :string, normalize: :downcase
  attribute :upcase_field, :string, normalize: :upcase
  attribute :blank_to_nil_field, :string, normalize: :blank_to_nil
  attribute :multi_field, :string, normalize: %i[strip squish downcase]
end
