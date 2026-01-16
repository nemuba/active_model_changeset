# ActiveModelChangeset

[![Gem Version](https://badge.fury.io/rb/active_model_changeset.svg)](https://badge.fury.io/rb/active_model_changeset)
[![Ruby](https://github.com/nemuba/active_model_changeset/workflows/Ruby/badge.svg)](https://github.com/nemuba/active_model_changeset/actions)
[![Coverage](https://img.shields.io/badge/coverage-93%25-brightgreen)](https://github.com/nemuba/active_model_changeset)

Uma gem utilitária para Ruby on Rails que fornece **changesets tipados, validados e com semântica de patch** para operações de criação e atualização de modelos.

## O Problema

Em aplicações Rails, é comum enfrentar desafios ao lidar com parâmetros de entrada:

- Receber parâmetros brutos de controllers ou APIs
- Aplicar type-casting e normalização de forma consistente
- Validar dados antes de persistir
- Calcular apenas os atributos que realmente mudaram
- Aplicar mudanças ao modelo de forma segura e previsível

O `ActiveModelChangeset` resolve todos esses problemas com uma abstração única e testável.

## Principais Características

| Característica | Descrição |
|----------------|-----------|
| 🔄 **Type-casting consistente** | Utiliza `ActiveModel::Attributes` para conversão de tipos |
| 🛡️ **Whitelist automática** | Apenas atributos declarados são aceitos |
| ✨ **Normalização declarativa** | Suporte a `strip`, `squish`, `downcase`, etc. |
| 📊 **Cálculo de diff** | Compara estado atual com novo estado |
| 🎯 **Patch semantics** | Gera hash somente com atributos alterados |
| ✅ **Validações integradas** | Compatível com `ActiveModel::Validations` |
| 📦 **Independente de ActiveRecord** | Funciona com POROs (Plain Old Ruby Objects) |

## Instalação

Adicione ao seu Gemfile:

```ruby
gem 'active_model_changeset'
```

E execute:

```bash
bundle install
```

Ou instale diretamente:

```bash
gem install active_model_changeset
```

## Como Usar

### Exemplo Básico

```ruby
class UserChangeset < ActiveModelChangeset::Base
  attribute :name, :string, normalize: :squish
  attribute :email, :string, normalize: [:strip, :downcase]
  attribute :age, :integer

  # Validações
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than: 0 }, allow_nil: true
end
```

### Criação de Registros

```ruby
changeset = UserChangeset.new(User.new, {
  name: "  João Silva  ",
  email: "JOAO@EXAMPLE.COM",
  age: "30"
})

if changeset.valid?
  user = User.create!(changeset.attributes_for_update)
  # => { name: "João Silva", email: "joao@example.com", age: 30 }
end
```

### Atualização de Registros (Patch Semantics)

```ruby
user = User.find(1)
# => #<User name: "João Silva", email: "joao@example.com", age: 30>

changeset = UserChangeset.new(user, { name: "João Santos", age: "30" })

changeset.changed?
# => true

changeset.changes
# => { name: ["João Silva", "João Santos"] }  # age não mudou, então não está incluído

if changeset.valid?
  user.update!(changeset.attributes_for_update)
end
```

### Verificando Mudanças

```ruby
changeset = UserChangeset.new(user, { name: "Novo Nome" })

changeset.changed?  # => true

changeset.changes          # => { name: ["Nome Antigo", "Novo Nome"] }
changeset.attributes_for_update  # => { name: "Novo Nome" }
```

### Normalizadores Disponíveis

| Normalizador | Descrição |
|--------------|----------|
| `:strip` | Remove espaços no início e fim da string |
| `:squish` | Remove espaços extras internos e externos |
| `:downcase` | Converte para minúsculas |
| `:upcase` | Converte para maiúsculas |
| `:blank_to_nil` | Converte strings vazias ou com apenas espaços para `nil` |

```ruby
class ProductChangeset < ActiveModelChangeset::Base
  attribute :name, :string, normalize: [:strip, :squish]
  attribute :sku, :string, normalize: :upcase
  attribute :description, :string, normalize: :blank_to_nil
end
```

### Métodos `#apply` e `#apply!`

Para simplificar o fluxo de atualização:

```ruby
changeset = UserChangeset.new(user, params)

# Retorna true/false
if changeset.apply
  redirect_to user_path(user)
else
  render :edit
end

# Ou levanta exceção
begin
  changeset.apply!
rescue ActiveModel::ValidationError => e
  # Tratar erro de validação do changeset
rescue ActiveRecord::RecordInvalid => e
  # Tratar erro de validação do modelo
end
```

## API Reference

### Métodos de Classe

| Método | Descrição |
|--------|----------|
| `.model(klass)` | Define a classe do modelo associada |
| `.attribute(name, type, normalize:)` | Declara um atributo com tipo e normalização opcional |
| `.normalizers` | Retorna hash de normalizadores configurados |
| `.declared_attribute_names` | Retorna array de nomes de atributos declarados |

### Métodos de Instância

| Método | Descrição |
|--------|----------|
| `#record` | Retorna o registro/modelo sendo modificado |
| `#raw_input` | Retorna os parâmetros de entrada originais (frozen) |
| `#changed?` | Retorna `true` se houver atributos alterados |
| `#changes` | Retorna hash `{ attr: [old, new] }` com mudanças |
| `#attributes_for_update(include_nil:)` | Retorna hash com atributos alterados |
| `#apply` | Aplica mudanças se válido, retorna `true/false` |
| `#apply!` | Aplica mudanças ou levanta exceção |

## Casos de Uso

### Em Controllers

```ruby
class UsersController < ApplicationController
  def create
    changeset = UserChangeset.new(User.new, user_params)

    if changeset.valid?
      @user = User.create!(changeset.attributes_for_update)
      render json: @user, status: :created
    else
      render json: { errors: changeset.errors }, status: :unprocessable_entity
    end
  end

  def update
    @user = User.find(params[:id])
    changeset = UserChangeset.new(@user, user_params)

    if changeset.valid? && changeset.changed?
      @user.update!(changeset.attributes_for_update)
    end

    render json: @user
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :age)
  end
end
```

### Em Service Objects

```ruby
class UpdateUserService
  def initialize(user, params)
    @user = user
    @changeset = UserChangeset.new(user, params)
  end

  def call
    return failure(@changeset.errors) unless @changeset.valid?
    return success(@user) unless @changeset.changed?

    @user.update!(@changeset.attributes_for_update)
    success(@user)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors)
  end

  private

  def success(user) = { success: true, user: user }
  def failure(errors) = { success: false, errors: errors }
end
```

## Desenvolvimento

Após clonar o repositório, execute:

```bash
bin/setup
```

Para rodar os testes:

```bash
bundle exec rspec
```

Para rodar os testes com cobertura:

```bash
bundle exec rspec
open coverage/index.html
```

Para rodar o RuboCop:

```bash
bundle exec rubocop
```

Para gerar a documentação:

```bash
bundle exec yard doc
bundle exec yard server --reload
```

Para abrir um console interativo:

```bash
bin/console
```

### Publicação

1. Atualize o número da versão em `lib/active_model_changeset/version.rb`
2. Execute `bundle exec rake release` para:
   - Criar uma tag git para a versão
   - Fazer push dos commits e da tag
   - Publicar o arquivo `.gem` no [rubygems.org](https://rubygems.org)

## Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça um fork do projeto
2. Crie sua feature branch (`git checkout -b feature/minha-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Faça push para a branch (`git push origin feature/minha-feature`)
5. Abra um Pull Request

Este projeto segue o [Código de Conduta](CODE_OF_CONDUCT.md). Ao participar, espera-se que você siga estas diretrizes.

## Licença

Esta gem está disponível como código aberto sob os termos da [Licença MIT](LICENSE.txt).

## Código de Conduta

Todos os participantes do projeto ActiveModelChangeset devem seguir o [Código de Conduta](CODE_OF_CONDUCT.md).
