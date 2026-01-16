# Changelog

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Unreleased]

## [0.1.0] - 2026-01-16

### Adicionado

- **Classe `ActiveModelChangeset::Base`** - Classe base para criar changesets
- **Type-casting** via `ActiveModel::Attributes`
- **Validações** via `ActiveModel::Validations`
- **Normalização declarativa** com opção `normalize:` no atributo
  - `:strip` - Remove espaços no início e fim
  - `:squish` - Remove espaços extras
  - `:downcase` - Converte para minúsculas
  - `:upcase` - Converte para maiúsculas
  - `:blank_to_nil` - Converte strings vazias para nil
- **Whitelist automática** - Apenas atributos declarados são aceitos
- **Detecção de mudanças**
  - `#changed?` - Verifica se há mudanças
  - `#changes` - Retorna hash com mudanças `{ attr: [old, new] }`
  - `#attributes_for_update` - Retorna hash com atributos alterados
- **Aplicação de mudanças**
  - `#apply` - Aplica mudanças se válido, retorna boolean
  - `#apply!` - Aplica mudanças ou levanta exceção
- **Suporte a ActionController::Parameters** via `to_unsafe_h`
- **Compatível com POROs** (Plain Old Ruby Objects)
- **Alias `Changeset`** para retrocompatibilidade
- **Documentação YARD** completa
- **Suite de testes** com 59 exemplos e 93%+ de cobertura
- **GitHub Actions** para CI/CD
- **SimpleCov** para relatórios de cobertura
