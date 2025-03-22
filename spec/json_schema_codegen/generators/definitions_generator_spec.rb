# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonSchemaCodegen::DefinitionsGenerator do
  let(:schema_path) { "spec/fixtures/schema.json" }
  let(:schema) { JSON.parse(File.read(schema_path)) }
  let(:generator) { described_class.new(schema) }

  describe "#available_definitions" do
    it "スキーマの定義一覧を返す" do
      definitions = generator.available_definitions
      expect(definitions).to be_an(Array)
      expect(definitions).not_to be_empty
      expect(definitions).to include("BlobResourceContents")
    end
  end

  describe "#generate_from_definition" do
    it "指定した定義からRubyコードを生成する" do
      code = generator.generate_from_definition("BlobResourceContents")
      expect(code).to include("BlobResourceContents = Data.define")
      expect(code).to include("def initialize(blob:")
      expect(code).to include("validate_format(uri, \"uri\"")
    end

    it "定義名をクラス名として使用する" do
      code = generator.generate_from_definition("BlobResourceContents")
      expect(code).to include("BlobResourceContents = Data.define")
    end

    it "カスタムクラス名を使用する" do
      code = generator.generate_from_definition("BlobResourceContents", "CustomBlob")
      expect(code).to include("CustomBlob = Data.define")
    end

    it "存在しない定義名の場合はエラーメッセージを返す" do
      code = generator.generate_from_definition("NonExistentDefinition")
      expect(code).to include("# 指定された定義「NonExistentDefinition」がJSONスキーマに存在しません")
    end
  end

  describe "#generate_all_definitions" do
    it "すべての定義からRubyコードを生成する" do
      codes = generator.generate_all_definitions
      expect(codes).to be_a(Hash)
      expect(codes).not_to be_empty
      expect(codes["BlobResourceContents"]).to include("BlobResourceContents = Data.define")
    end
  end

  describe "#generate_multiple_definitions" do
    it "指定した複数の定義からRubyコードを生成する" do
      code = generator.generate_multiple_definitions(["BlobResourceContents", "TextContent"])
      expect(code).to include("BlobResourceContents = Data.define")
      expect(code).to include("TextContent = Data.define")
    end

    it "空の配列が指定された場合はエラーメッセージを返す" do
      code = generator.generate_multiple_definitions([])
      expect(code).to include("# 定義名が指定されていません")
    end
  end
end
