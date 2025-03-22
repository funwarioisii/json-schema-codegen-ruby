# frozen_string_literal: true

require "json"
require "json_schema_codegen/version"
require "json_schema_codegen/generator"
require "json_schema_codegen/generators/definitions_generator"

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

  # JSONスキーマの定義セクションから特定の定義に基づいてクラスを生成します
  # @param schema_json [String] JSONスキーマ文字列
  # @param definition_name [String] 定義名
  # @param class_name [String, nil] 生成するクラス名（nilの場合は定義名が使用されます）
  # @return [String] 生成されたRubyコード
  def self.generate_from_definition(schema_json, definition_name, class_name = nil)
    schema = JSON.parse(schema_json)
    generator = DefinitionsGenerator.new(schema)
    generator.generate_from_definition(definition_name, class_name)
  end

  # JSONスキーマファイルの定義セクションから特定の定義に基づいてクラスを生成します
  # @param schema_path [String] JSONスキーマファイルのパス
  # @param definition_name [String] 定義名
  # @param class_name [String, nil] 生成するクラス名（nilの場合は定義名が使用されます）
  # @return [String] 生成されたRubyコード
  def self.generate_from_file_definition(schema_path, definition_name, class_name = nil)
    schema_json = File.read(schema_path)
    generate_from_definition(schema_json, definition_name, class_name)
  end

  # JSONスキーマの定義セクションから複数の定義に基づいてクラスを生成します
  # @param schema_json [String] JSONスキーマ文字列
  # @param definition_names [Array<String>] 定義名の配列
  # @return [String] 生成されたRubyコード
  def self.generate_from_multiple_definitions(schema_json, definition_names)
    schema = JSON.parse(schema_json)
    generator = DefinitionsGenerator.new(schema)
    generator.generate_multiple_definitions(definition_names)
  end

  # JSONスキーマファイルの定義セクションから複数の定義に基づいてクラスを生成します
  # @param schema_path [String] JSONスキーマファイルのパス
  # @param definition_names [Array<String>] 定義名の配列
  # @return [String] 生成されたRubyコード
  def self.generate_from_file_multiple_definitions(schema_path, definition_names)
    schema_json = File.read(schema_path)
    generate_from_multiple_definitions(schema_json, definition_names)
  end

  # JSONスキーマに含まれる定義名の一覧を取得します
  # @param schema_json [String] JSONスキーマ文字列
  # @return [Array<String>] 定義名の配列
  def self.list_definitions(schema_json)
    schema = JSON.parse(schema_json)
    generator = DefinitionsGenerator.new(schema)
    generator.available_definitions
  end

  # JSONスキーマファイルに含まれる定義名の一覧を取得します
  # @param schema_path [String] JSONスキーマファイルのパス
  # @return [Array<String>] 定義名の配列
  def self.list_definitions_from_file(schema_path)
    schema_json = File.read(schema_path)
    list_definitions(schema_json)
  end
end
