# frozen_string_literal: true

# MockRecord simula um modelo ActiveRecord para testes
# Suporta leitura/escrita de atributos e métodos update/update!

# rubocop:disable Naming/PredicateMethod
class MockRecord
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :age, :integer
  attribute :bio, :string

  def update(attrs)
    attrs.each { |k, v| public_send("#{k}=", v) }
    true
  end

  def update!(attrs)
    update(attrs)
  end
end

# MockRecordWithValidation simula um modelo com validação que pode falhar
class MockRecordWithFailingUpdate < MockRecord
  def update(_attrs)
    false
  end

  def update!(_attrs)
    raise StandardError, "Validation failed"
  end
end
# rubocop:enable Naming/PredicateMethod
