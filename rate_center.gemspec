# frozen_string_literal: true

require_relative "lib/rate_center/version"

Gem::Specification.new do |spec|
  spec.name = "rate_center"
  spec.version = RateCenter::VERSION
  spec.authors = ["David Wilkie"]
  spec.email = ["dwilkie@gmail.com"]

  spec.summary = "TODO: Write a short summary, because RubyGems requires one."
  spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = [ "lib" ]

  # Uncomment to register a new dependency of your gem

  spec.add_development_dependency "multi_xml"
  spec.add_development_dependency "ox"
  spec.add_development_dependency "faraday"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "countries"
  spec.add_development_dependency "ostruct"
  spec.add_development_dependency "rubyzip"
  spec.add_development_dependency "csv"
  spec.add_development_dependency "geocoder"
  spec.add_development_dependency "logger"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
