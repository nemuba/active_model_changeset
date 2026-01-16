# frozen_string_literal: true

require_relative "lib/active_model_changeset/version"

Gem::Specification.new do |spec|
  spec.name = "active_model_changeset"
  spec.version = ActiveModelChangeset::VERSION
  spec.authors = ["Alef ojeda de Oliveira"]
  spec.email = ["nemubatubag@gmail.com"]

  spec.summary = "Typed, validated changesets for ActiveModel with patch semantics"
  spec.description = <<~DESC
    ActiveModelChangeset provides a lightweight changeset abstraction for Ruby on Rails
    applications. It combines type casting, attribute normalization, validation and
    diff calculation into a single object, enabling safe and explicit create/update
    operations with patch semantics.

    The gem is designed for service objects and APIs, allowing developers to whitelist
    attributes, apply transformations, validate input and update models using only
    changed values, without relying on ActiveRecord callbacks or controllers.
  DESC

  spec.homepage = "https://github.com/nemuba/active_model_changeset"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}.git"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/doc/index.html"
  spec.metadata["yard.run"] = "yri, yard"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activemodel",   ">= 6.1"
  spec.add_dependency "activesupport", ">= 6.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
