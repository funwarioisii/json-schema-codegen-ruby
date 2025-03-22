# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = "json_schema_codegen"
  spec.version     = "0.1.0"
  spec.authors     = ["funwarioisii"]
  spec.email       = [""]
  spec.summary     = "JSONスキーマからRubyコードを生成するライブラリ"
  spec.description = "JSONスキーマの定義からRubyの検証付きData.defineクラスを生成します"
  spec.homepage    = "https://github.com/funwarioisii/json-schema-codegen-ruby"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir.glob("lib/**/*")
  spec.require_paths = ["lib"]
end 