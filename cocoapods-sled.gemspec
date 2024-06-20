# frozen_string_literal: true

require_relative "lib/cocoapods-sled/gem_version.rb"

Gem::Specification.new do |spec|
  spec.name          = "cocoapods-sled"
  spec.version       = Pod::Sled::VERSION
  spec.authors       = ["赵守文"]
  spec.email         = ["zsw19911017@163.com"]

  spec.summary       = "Cocoapods-sled 是一个简单易用的 Cocoapods 插件，通过缓存和复用Xcode编译结果完成二进制化"
  spec.description   = "Cocoapods-sled 是一个简单易用的 Cocoapods 插件，通过缓存和复用Xcode编译结果完成二进制化"
  spec.homepage      = "https://github.com/git179979506/cocoapods-sled"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir['lib/**/*']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
