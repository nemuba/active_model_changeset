# frozen_string_literal: true

RSpec.describe ActiveModelChangeset::Base do
  describe "métodos de classe" do
    describe ".model" do
      it "armazena a classe do modelo quando definida" do
        expect(ChangesetWithModel.model).to eq(MockRecord)
      end

      it "retorna nil quando não configurado" do
        expect(SimpleChangeset.model).to be_nil
      end
    end

    describe ".attribute" do
      it "declara um atributo com tipo padrão :string" do
        expect(SimpleChangeset.attribute_types["name"]).to be_a(ActiveModel::Type::String)
      end

      it "declara um atributo com tipo específico" do
        expect(SimpleChangeset.attribute_types["value"]).to be_a(ActiveModel::Type::Integer)
      end

      it "registra normalizadores quando :normalize é passado" do
        expect(UserChangeset.normalizers[:name]).to eq(%i[strip squish])
      end

      it "aceita um único normalizador como Symbol" do
        expect(ChangesetWithAllNormalizers.normalizers[:strip_field]).to eq([:strip])
      end

      it "aceita múltiplos normalizadores como Array" do
        expect(ChangesetWithAllNormalizers.normalizers[:multi_field]).to eq(%i[strip squish downcase])
      end
    end

    describe ".normalizers" do
      it "retorna hash vazio quando nenhum normalizador configurado" do
        expect(SimpleChangeset.normalizers).to eq({})
      end

      it "retorna hash com normalizadores por atributo" do
        expect(UserChangeset.normalizers).to include(:name, :email, :bio)
      end
    end

    describe ".declared_attribute_names" do
      it "retorna array de symbols com nomes dos atributos" do
        expect(SimpleChangeset.declared_attribute_names).to contain_exactly(:name, :value)
      end

      it "inclui todos os atributos declarados" do
        expect(UserChangeset.declared_attribute_names).to contain_exactly(:name, :email, :age, :bio)
      end
    end
  end

  describe "inicialização" do
    describe "#initialize" do
      let(:record) { MockRecord.new(name: "Original", email: "original@example.com") }

      it "armazena o record" do
        changeset = SimpleChangeset.new(record, { name: "Test" })
        expect(changeset.record).to eq(record)
      end

      it "armazena o raw_input como frozen" do
        input = { name: "Test" }
        changeset = SimpleChangeset.new(record, input)
        expect(changeset.raw_input).to be_frozen
      end

      it "extrai apenas atributos declarados do input" do
        changeset = SimpleChangeset.new(record, { name: "Test", unknown: "value" })
        expect(changeset.name).to eq("Test")
        expect(changeset).not_to respond_to(:unknown)
      end

      it "aceita Hash como input" do
        changeset = SimpleChangeset.new(record, { name: "Test" })
        expect(changeset.name).to eq("Test")
      end

      it "lida com input vazio" do
        changeset = SimpleChangeset.new(record, {})
        expect(changeset.name).to be_nil
      end

      it "aplica normalização aos atributos" do
        changeset = UserChangeset.new(record, { name: "  João   Silva  ", email: "JOAO@EXAMPLE.COM" })
        expect(changeset.name).to eq("João Silva")
        expect(changeset.email).to eq("joao@example.com")
      end

      it "aceita input com chaves como strings" do
        changeset = SimpleChangeset.new(record, { "name" => "Test" })
        expect(changeset.name).to eq("Test")
      end
    end
  end

  describe "detecção de mudanças" do
    let(:record) { MockRecord.new(name: "Original", email: "original@example.com", age: 30) }

    describe "#changed?" do
      it "retorna false quando não há mudanças" do
        changeset = UserChangeset.new(record, { name: "Original", email: "original@example.com", age: 30 })
        expect(changeset.changed?).to be(false)
      end

      it "retorna true quando há pelo menos uma mudança" do
        changeset = UserChangeset.new(record, { name: "Novo Nome", email: "original@example.com", age: 30 })
        expect(changeset.changed?).to be(true)
      end

      it "detecta mudança após normalização" do
        changeset = UserChangeset.new(record, { name: "Original", email: "ORIGINAL@EXAMPLE.COM", age: 30 })
        expect(changeset.changed?).to be(false)
      end
    end

    describe "#changes" do
      it "retorna hash vazio quando não há mudanças" do
        changeset = UserChangeset.new(record, { name: "Original", email: "original@example.com", age: 30 })
        expect(changeset.changes).to eq({})
      end

      it "retorna hash com formato {attr: [old, new]}" do
        changeset = UserChangeset.new(record, { name: "Novo Nome", email: "original@example.com", age: 30 })
        expect(changeset.changes).to eq({ name: ["Original", "Novo Nome"] })
      end

      it "detecta mudança de nil para valor" do
        record_sem_bio = MockRecord.new(name: "Test", bio: nil)
        changeset = UserChangeset.new(record_sem_bio, { name: "Test", bio: "Uma bio" })
        expect(changeset.changes[:bio]).to eq([nil, "Uma bio"])
      end

      it "detecta mudança de valor para nil via blank_to_nil" do
        record_com_bio = MockRecord.new(name: "Test", bio: "Uma bio")
        changeset = UserChangeset.new(record_com_bio, { name: "Test", bio: "   " })
        expect(changeset.changes[:bio]).to eq(["Uma bio", nil])
      end
    end

    describe "#attributes_for_update" do
      it "retorna hash com atributos modificados" do
        changeset = UserChangeset.new(record, { name: "Novo Nome", email: "novo@example.com" })
        expect(changeset.attributes_for_update).to include(name: "Novo Nome", email: "novo@example.com")
      end

      it "exclui atributos com valor nil por padrão" do
        changeset = UserChangeset.new(record, { name: "Novo Nome", bio: nil })
        expect(changeset.attributes_for_update).not_to have_key(:bio)
      end

      it "inclui atributos nil quando include_nil: true" do
        record_com_bio = MockRecord.new(name: "Test", bio: "Uma bio")
        changeset = UserChangeset.new(record_com_bio, { name: "Test", bio: "  " })
        expect(changeset.attributes_for_update(include_nil: true)).to have_key(:bio)
      end

      it "retorna hash vazio quando não há alterações" do
        changeset = UserChangeset.new(record, { name: "Original" })
        expect(changeset.attributes_for_update).to eq({})
      end
    end
  end

  describe "normalização" do
    let(:record) { MockRecord.new }

    describe ":strip" do
      it "remove espaços no início e fim de strings" do
        changeset = ChangesetWithAllNormalizers.new(record, { strip_field: "  texto  " })
        expect(changeset.strip_field).to eq("texto")
      end

      it "não altera valores não-string" do
        changeset = SimpleChangeset.new(record, { value: 123 })
        expect(changeset.value).to eq(123)
      end
    end

    describe ":squish" do
      it "remove espaços extras internos e externos" do
        changeset = ChangesetWithAllNormalizers.new(record, { squish_field: "  texto   com   espaços  " })
        expect(changeset.squish_field).to eq("texto com espaços")
      end
    end

    describe ":downcase" do
      it "converte string para minúsculas" do
        changeset = ChangesetWithAllNormalizers.new(record, { downcase_field: "TEXTO MAIÚSCULO" })
        expect(changeset.downcase_field).to eq("texto maiúsculo")
      end
    end

    describe ":upcase" do
      it "converte string para maiúsculas" do
        changeset = ChangesetWithAllNormalizers.new(record, { upcase_field: "texto minúsculo" })
        expect(changeset.upcase_field).to eq("TEXTO MINÚSCULO")
      end
    end

    describe ":blank_to_nil" do
      it "converte string vazia para nil" do
        changeset = ChangesetWithAllNormalizers.new(record, { blank_to_nil_field: "" })
        expect(changeset.blank_to_nil_field).to be_nil
      end

      it "converte string com espaços para nil" do
        changeset = ChangesetWithAllNormalizers.new(record, { blank_to_nil_field: "   " })
        expect(changeset.blank_to_nil_field).to be_nil
      end

      it "mantém valores não-blank" do
        changeset = ChangesetWithAllNormalizers.new(record, { blank_to_nil_field: "texto" })
        expect(changeset.blank_to_nil_field).to eq("texto")
      end
    end

    describe "múltiplos normalizadores" do
      it "aplica normalizadores em sequência" do
        changeset = ChangesetWithAllNormalizers.new(record, { multi_field: "  TEXTO   COM   ESPAÇOS  " })
        expect(changeset.multi_field).to eq("texto com espaços")
      end
    end
  end

  describe "validações" do
    let(:record) { MockRecord.new }

    it "é válido quando todas as validações passam" do
      changeset = UserChangeset.new(record, { name: "João", email: "joao@example.com", age: 25 })
      expect(changeset).to be_valid
    end

    it "é inválido quando validação de presença falha" do
      changeset = UserChangeset.new(record, { name: "", email: "joao@example.com" })
      expect(changeset).not_to be_valid
      expect(changeset.errors[:name]).to include("can't be blank")
    end

    it "é inválido quando validação de numericality falha" do
      changeset = UserChangeset.new(record, { name: "João", email: "joao@example.com", age: -5 })
      expect(changeset).not_to be_valid
      expect(changeset.errors[:age]).to include("must be greater than 0")
    end

    it "permite age nil" do
      changeset = UserChangeset.new(record, { name: "João", email: "joao@example.com", age: nil })
      expect(changeset).to be_valid
    end
  end

  describe "aplicação de mudanças" do
    describe "#apply" do
      let(:record) { MockRecord.new(name: "Original", email: "original@example.com") }

      context "quando changeset é válido" do
        it "chama update no record com atributos alterados" do
          changeset = UserChangeset.new(record, { name: "Novo Nome", email: "novo@example.com" })

          expect(record).to receive(:update).with(hash_including(name: "Novo Nome")).and_call_original
          changeset.apply
        end

        it "retorna true em caso de sucesso" do
          changeset = UserChangeset.new(record, { name: "Novo Nome", email: "novo@example.com" })
          expect(changeset.apply).to be(true)
        end

        it "retorna false se update retornar false" do
          failing_record = MockRecordWithFailingUpdate.new(name: "Original")
          changeset = SimpleChangeset.new(failing_record, { name: "Novo Nome" })
          expect(changeset.apply).to be(false)
        end
      end

      context "quando changeset é inválido" do
        it "retorna false sem chamar update" do
          changeset = UserChangeset.new(record, { name: "", email: "" })

          expect(record).not_to receive(:update)
          expect(changeset.apply).to be(false)
        end
      end
    end

    describe "#apply!" do
      let(:record) { MockRecord.new(name: "Original", email: "original@example.com") }

      context "quando changeset é inválido" do
        it "levanta ActiveModel::ValidationError" do
          changeset = UserChangeset.new(record, { name: "", email: "" })

          expect { changeset.apply! }.to raise_error(ActiveModel::ValidationError)
        end
      end

      context "quando changeset é válido" do
        it "chama update! no record" do
          changeset = UserChangeset.new(record, { name: "Novo Nome", email: "novo@example.com" })

          expect(record).to receive(:update!).and_call_original
          changeset.apply!
        end

        it "propaga exceção se update! falhar" do
          failing_record = MockRecordWithFailingUpdate.new(name: "Original")
          changeset = SimpleChangeset.new(failing_record, { name: "Novo Nome" })

          expect { changeset.apply! }.to raise_error(StandardError, "Validation failed")
        end

        it "retorna true em caso de sucesso" do
          changeset = UserChangeset.new(record, { name: "Novo Nome", email: "novo@example.com" })
          expect(changeset.apply!).to be(true)
        end
      end
    end
  end

  describe "edge cases" do
    it "lida com record que não responde aos atributos" do
      record_simples = Object.new
      changeset = SimpleChangeset.new(record_simples, { name: "Test" })

      # Deve detectar mudança porque record não tem o atributo
      expect(changeset.changed?).to be(true)
    end

    it "não modifica o raw_input original" do
      input = { name: "Test" }
      original_input = input.dup

      SimpleChangeset.new(MockRecord.new, input)

      expect(input).to eq(original_input)
    end

    it "lida com normalização em valores nil" do
      changeset = ChangesetWithAllNormalizers.new(MockRecord.new, { strip_field: nil })
      expect(changeset.strip_field).to be_nil
    end

    it "funciona com Faker para dados de teste" do
      name = Faker::Name.name
      email = Faker::Internet.email

      record = MockRecord.new
      changeset = UserChangeset.new(record, { name: name, email: email })

      expect(changeset.name).to eq(name.squish)
      expect(changeset.email).to eq(email.downcase.strip)
    end
  end

  describe "integração" do
    it "valida, normaliza e aplica mudanças em fluxo completo" do
      record = MockRecord.new(name: "Original", email: "original@example.com", age: 25)

      changeset = UserChangeset.new(record, {
                                      name: "  João   Santos  ",
                                      email: "JOAO.SANTOS@EXAMPLE.COM",
                                      age: "30"
                                    })

      expect(changeset).to be_valid
      expect(changeset.changed?).to be(true)
      expect(changeset.changes.keys).to contain_exactly(:name, :email, :age)

      expect(changeset.apply).to be(true)

      expect(record.name).to eq("João Santos")
      expect(record.email).to eq("joao.santos@example.com")
      expect(record.age).to eq(30)
    end

    it "funciona com POROs (Plain Old Ruby Objects)" do
      poro = Struct.new(:name, :value, keyword_init: true).new(name: "Old", value: 10)
      changeset = SimpleChangeset.new(poro, { name: "New", value: 20 })

      expect(changeset.changed?).to be(true)
      expect(changeset.changes).to eq({ name: %w[Old New], value: [10, 20] })
    end
  end
end
