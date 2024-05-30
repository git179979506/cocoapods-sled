# frozen_string_literal: true

require_relative "lib/cocoapods-sled/gem_version.rb"

Gem::Specification.new do |spec|
  spec.name          = "cocoapods-sled"
  spec.version       = Pod::Sled::VERSION
  spec.authors       = ["赵守文"]
  spec.email         = ["zsw19911017@163.com"]

  spec.summary       = "Cocoapods-sled：一个轻量级且高效的Cocoapods插件，实现二进制化功能。"
  spec.description   = <<-DESC
  Cocoapods-sled 是一款轻量级且易于使用的Cocoapods插件，旨在通过二进制化处理提升项目构建速度。它的核心优势在于：
  
  1. **编译结果缓存**：利用缓存机制，复用编译结果，避免不必要的重复编译，从而提高开发效率。
  2. **二进制化处理**：自动将可复用的依赖项转换为二进制格式，提升构建速度。
  3. **低接入成本**：易于集成，开发者可以快速将其加入到现有的Xcode项目中，无需复杂的配置和基建即可开始优化构建流程。
  
  Cocoapods-sled 致力于成为iOS项目构建优化的首选工具，帮助开发者以更低的成本实现更高效的开发流程。
  DESC
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
