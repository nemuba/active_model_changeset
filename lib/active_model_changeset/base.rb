# frozen_string_literal: true

module ActiveModelChangeset
  # Base é a classe principal que encapsula a lógica de validação, normalização
  # e cálculo de diferenças para operações de criação e atualização de modelos.
  #
  # Ela combina type-casting via ActiveModel::Attributes, normalização declarativa,
  # validações e semântica de patch em uma única classe reutilizável.
  #
  # @example Definindo um changeset
  #   class UserChangeset < ActiveModelChangeset::Base
  #     model User
  #
  #     attribute :name, :string, normalize: [:strip, :squish]
  #     attribute :email, :string, normalize: [:strip, :downcase]
  #     attribute :age, :integer
  #
  #     validates :name, presence: true
  #     validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  #   end
  #
  # @example Usando para atualização
  #   user = User.find(1)
  #   changeset = UserChangeset.new(user, params)
  #
  #   if changeset.valid? && changeset.changes.any?
  #     user.update!(changeset.attributes_for_update)
  #   end
  #
  # @see https://api.rubyonrails.org/classes/ActiveModel/Attributes.html
  # @see https://api.rubyonrails.org/classes/ActiveModel/Validations.html
  # :rubocop:disable Metrics/ClassLength
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    # Funções de normalização disponíveis para uso com a opção `normalize:`
    #
    # @example
    #   attribute :name, :string, normalize: [:strip, :squish]
    #
    NORMALIZER_FUNCS = {
      strip: ->(v) { v.is_a?(String) ? v.strip : v },
      squish: ->(v) { v.is_a?(String) ? v.squish : v },
      downcase: ->(v) { v.is_a?(String) ? v.downcase : v },
      upcase: ->(v) { v.is_a?(String) ? v.upcase : v },
      blank_to_nil: ->(v) { v.respond_to?(:blank?) && v.blank? ? nil : v }
    }.freeze

    class << self
      # Define ou retorna a classe do modelo associada ao changeset.
      #
      # @param klass [Class, nil] a classe do modelo (ex: User, Post)
      # @return [Class, nil] a classe do modelo configurada
      #
      # @example
      #   class UserChangeset < ActiveModelChangeset::Base
      #     model User
      #   end
      #
      def model(klass = nil)
        if klass
          @model_class = klass
        else
          @model_class
        end
      end

      # Declara um atributo no changeset com suporte a normalização.
      #
      # Estende o método `attribute` do ActiveModel::Attributes para
      # suportar a opção `normalize:` que aplica transformações ao valor.
      #
      # @param name [Symbol] nome do atributo
      # @param type [Symbol] tipo do atributo (:string, :integer, :boolean, etc.)
      # @param options [Hash] opções adicionais
      # @option options [Symbol, Array<Symbol>] :normalize normalizadores a aplicar
      #
      # @example
      #   attribute :email, :string, normalize: [:strip, :downcase]
      #   attribute :name, :string, normalize: :squish
      #
      # @return [void]
      #
      def attribute(name, type = :string, **options)
        normalize = options.delete(:normalize)
        super
        normalizers[name.to_sym] = Array(normalize).compact.map(&:to_sym) if normalize
      end

      # Retorna o hash de normalizadores configurados por atributo.
      #
      # @return [Hash{Symbol => Array<Symbol>}] mapa de atributo para lista de normalizadores
      #
      def normalizers
        @normalizers ||= {}
      end

      # Retorna os nomes dos atributos declarados no changeset.
      #
      # @return [Array<Symbol>] lista de nomes de atributos
      #
      def declared_attribute_names
        attribute_types.keys.map(&:to_sym)
      end
    end

    # @return [Object] o registro/modelo sendo modificado
    attr_reader :record

    # @return [Hash] os parâmetros de entrada originais (antes de processamento)
    attr_reader :raw_input

    # Inicializa um novo changeset.
    #
    # @param record [Object] o registro existente para comparação (pode ser nil para criação)
    # @param input [Hash, ActionController::Parameters] os parâmetros de entrada
    #
    # @example Atualização
    #   user = User.find(1)
    #   changeset = UserChangeset.new(user, { name: "Novo Nome" })
    #
    # @example Criação (record vazio)
    #   changeset = UserChangeset.new(User.new, params)
    #
    def initialize(record, input = {})
      @record = record
      @raw_input = input.dup.freeze
      super(extract_declared_attributes(input))
      normalize_attributes!
    end

    # Retorna os atributos que foram alterados, prontos para update.
    #
    # Apenas atributos que diferem do registro original são incluídos.
    # Por padrão, valores nil são excluídos do resultado.
    #
    # @param include_nil [Boolean] se true, inclui atributos com valor nil
    # @return [Hash{Symbol => Object}] hash com atributos alterados
    #
    # @example
    #   changeset.attributes_for_update
    #   # => { name: "João Santos" }
    #
    #   changeset.attributes_for_update(include_nil: true)
    #   # => { name: "João Santos", bio: nil }
    #
    def attributes_for_update(include_nil: false)
      self.class.declared_attribute_names.each_with_object({}) do |name, hash|
        next unless changed_attribute?(name)

        value = public_send(name)
        next if !include_nil && value.nil?

        hash[name] = value
      end
    end

    # Retorna um hash com as mudanças no formato { atributo: [valor_antigo, valor_novo] }.
    #
    # Similar ao `ActiveModel::Dirty#changes`, mas calcula a diferença
    # entre o changeset e o registro original.
    #
    # @return [Hash{Symbol => Array}] hash de mudanças
    #
    # @example
    #   changeset.changes
    #   # => { name: ["João Silva", "João Santos"] }
    #
    def changes
      self.class.declared_attribute_names.each_with_object({}) do |name, hash|
        next unless changed_attribute?(name)

        hash[name] = [record_value(name), public_send(name)]
      end
    end

    # Verifica se há alguma mudança no changeset.
    #
    # @return [Boolean] true se houver pelo menos um atributo alterado
    #
    def changed?
      self.class.declared_attribute_names.any? { |name| changed_attribute?(name) }
    end

    # Aplica as mudanças ao registro se o changeset for válido.
    #
    # @return [Boolean] true se a atualização foi bem-sucedida, false caso contrário
    #
    # @example
    #   if changeset.apply
    #     redirect_to user_path
    #   else
    #     render :edit
    #   end
    #
    def apply
      return false unless valid?

      record.update(attributes_for_update)
    end

    # Aplica as mudanças ao registro, levantando exceção se inválido.
    #
    # @raise [ActiveModel::ValidationError] se o changeset for inválido
    # @raise [ActiveRecord::RecordInvalid] se o update! falhar
    # @return [Boolean] true se a atualização foi bem-sucedida
    #
    # @example
    #   begin
    #     changeset.apply!
    #   rescue ActiveModel::ValidationError => e
    #     # tratar erro de validação do changeset
    #   rescue ActiveRecord::RecordInvalid => e
    #     # tratar erro de validação do modelo
    #   end
    #
    def apply!
      raise ActiveModel::ValidationError, self unless valid?

      record.update!(attributes_for_update)
    end

    private

    # Aplica os normalizadores configurados a cada atributo.
    #
    # @return [void]
    #
    def normalize_attributes!
      self.class.normalizers.each do |attr, normalizer_keys|
        value = public_send(attr)
        normalized_value = apply_normalizers(value, normalizer_keys)
        public_send("#{attr}=", normalized_value)
      end
    end

    # Aplica uma lista de normalizadores a um valor.
    #
    # @param value [Object] o valor a ser normalizado
    # @param normalizer_keys [Array<Symbol>] lista de chaves de normalizadores
    # @return [Object] o valor normalizado
    #
    def apply_normalizers(value, normalizer_keys)
      normalizer_keys.reduce(value) do |val, key|
        fn = NORMALIZER_FUNCS[key]
        fn ? fn.call(val) : val
      end
    end

    # Extrai apenas os atributos declarados do input.
    #
    # Funciona como whitelist automática, aceitando apenas atributos
    # explicitamente declarados no changeset.
    #
    # @param input [Hash, ActionController::Parameters] parâmetros de entrada
    # @return [Hash{Symbol => Object}] hash filtrado com apenas atributos declarados
    #
    def extract_declared_attributes(input)
      hash = convert_to_hash(input)
      declared = self.class.declared_attribute_names

      hash.each_with_object({}) do |(key, value), acc|
        key_sym = safe_to_sym(key)
        acc[key_sym] = value if key_sym && declared.include?(key_sym)
      end
    end

    # Converte o input para hash de forma segura.
    #
    # Suporta ActionController::Parameters (to_unsafe_h) e objetos
    # que respondem a to_h.
    #
    # @param input [Object] o objeto a ser convertido
    # @return [Hash] o hash resultante
    #
    def convert_to_hash(input)
      if input.respond_to?(:to_unsafe_h)
        input.to_unsafe_h
      elsif input.respond_to?(:to_h)
        input.to_h
      else
        {}
      end
    end

    # Converte uma chave para Symbol de forma segura.
    #
    # @param key [Object] a chave a ser convertida
    # @return [Symbol, nil] o symbol ou nil se a conversão falhar
    #
    def safe_to_sym(key)
      key.to_sym
    rescue StandardError
      nil
    end

    # Verifica se um atributo específico foi alterado.
    #
    # @param name [Symbol] nome do atributo
    # @return [Boolean] true se o valor no changeset difere do registro
    #
    def changed_attribute?(name)
      record_value(name) != public_send(name)
    end

    # Obtém o valor atual de um atributo no registro.
    #
    # @param name [Symbol] nome do atributo
    # @return [Object, nil] o valor do atributo ou nil se não existir
    #
    def record_value(name)
      return unless record.respond_to?(name)

      record.public_send(name)
    end
  end
end
