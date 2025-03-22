# frozen_string_literal: true

require "json"
require "json_schema_codegen/version"
require "json_schema_codegen/generator"

module JsonSchemaCodegen
  class Error < StandardError; end

  # JSONスキーマからRubyのData.defineクラスを生成します
  # @param schema_json [String] JSONスキーマ文字列
  # @param class_name [String] 生成するクラス名
  # @return [String] 生成されたRubyコード
  def self.generate(schema_json, class_name)
    schema = JSON.parse(schema_json)
    generator = Generator.new(schema, class_name)
    generator.generate
  end

  # JSONスキーマファイルからRubyのData.defineクラスを生成します
  # @param schema_path [String] JSONスキーマファイルのパス
  # @param class_name [String] 生成するクラス名
  # @return [String] 生成されたRubyコード
  def self.generate_from_file(schema_path, class_name)
    schema_json = File.read(schema_path)
    generate(schema_json, class_name)
  end
end 