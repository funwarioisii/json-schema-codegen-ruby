# frozen_string_literal: true

module JsonSchemaCodegen
  # 複数の定義からRubyクラスを生成するジェネレーター
  class DefinitionsGenerator
    def initialize(schema)
      @schema = schema
      @base_generator = Generator
    end

    # 指定した定義からクラスを生成します
    # @param definition_name [String] 定義名
    # @param class_name [String, nil] 生成するクラス名（nilの場合は定義名が使用されます）
    # @return [String] 生成されたRubyコード
    def generate_from_definition(definition_name, class_name = nil)
      unless @schema["definitions"] && @schema["definitions"][definition_name]
        return "# 指定された定義「#{definition_name}」がJSONスキーマに存在しません"
      end

      definition = @schema["definitions"][definition_name]
      actual_class_name = class_name || definition_name

      generator = @base_generator.new(definition, actual_class_name)
      generator.generate
    end

    # すべての定義からクラスを生成します
    # @return [Hash] 定義名をキー、生成されたコードを値とするハッシュ
    def generate_all_definitions
      return {} unless @schema["definitions"]

      result = {}
      @schema["definitions"].each_key do |definition_name|
        code = generate_from_definition(definition_name)
        result[definition_name] = code
      end

      result
    end

    # 指定した定義からクラスを生成し、1つのファイルに結合します
    # @param definition_names [Array<String>] 生成する定義名の配列
    # @return [String] 結合されたRubyコード
    def generate_multiple_definitions(definition_names)
      return "# 定義名が指定されていません" if definition_names.empty?

      codes = []
      definition_names.each do |definition_name|
        code = generate_from_definition(definition_name)
        codes << code
      end

      codes.join("\n\n")
    end

    # 使用可能な定義名の一覧を返します
    # @return [Array<String>] 定義名の配列
    def available_definitions
      return [] unless @schema["definitions"]
      @schema["definitions"].keys
    end
  end
end
