# frozen_string_literal: true

require_relative "lib/stack0/version"

Gem::Specification.new do |spec|
  spec.name = "stack0"
  spec.version = Stack0::VERSION
  spec.authors = ["Stack0"]
  spec.email = ["support@stack0.dev"]

  spec.summary = "Ruby SDK for the Stack0 platform"
  spec.description = "Official Ruby SDK for Stack0 - Email, CDN, Screenshots, Extraction, Integrations, and Marketing APIs"
  spec.homepage = "https://stack0.dev"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/stack0/stack0-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/stack0/stack0-ruby/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://docs.stack0.dev/sdk/ruby"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", ">= 1.0", "< 3.0"
  spec.add_dependency "faraday-multipart", "~> 1.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
end
