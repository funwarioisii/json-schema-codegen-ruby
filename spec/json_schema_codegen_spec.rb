# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonSchemaCodegen do
  it "has a version number" do
    expect(JsonSchemaCodegen::VERSION).not_to be nil
  end

  describe ".generate" do
    let(:schema_json) { File.read("spec/fixtures/user_schema.json") }
    let(:class_name) { "User" }

    it "generates a valid Ruby class" do
      code = described_class.generate(schema_json, class_name)
      expect(code).to include("User = Data.define")
      expect(code).to include("def initialize")
    end
  end

  describe ".generate_from_file" do
    let(:schema_path) { "spec/fixtures/user_schema.json" }
    let(:class_name) { "User" }

    it "reads the file and generates a valid Ruby class" do
      code = described_class.generate_from_file(schema_path, class_name)
      expect(code).to include("User = Data.define")
      expect(code).to include("def initialize")
    end
  end

  describe ".generate_from_definition" do
    let(:schema_path) { "spec/fixtures/schema.json" }
    let(:schema_json) { File.read(schema_path) }
    let(:definition_name) { "BlobResourceContents" }
    let(:class_name) { "CustomBlob" }

    it "generates Ruby code from a specific definition" do
      code = described_class.generate_from_definition(schema_json, definition_name)
      expect(code).to include("BlobResourceContents = Data.define")
      expect(code).to include("def initialize")
    end

    it "uses a custom class name when provided" do
      code = described_class.generate_from_definition(schema_json, definition_name, class_name)
      expect(code).to include("CustomBlob = Data.define")
      expect(code).to include("def initialize")
    end
  end

  describe ".generate_from_file_definition" do
    let(:schema_path) { "spec/fixtures/schema.json" }
    let(:definition_name) { "BlobResourceContents" }
    let(:class_name) { "CustomBlob" }

    it "reads a file and generates Ruby code from a specific definition" do
      code = described_class.generate_from_file_definition(schema_path, definition_name)
      expect(code).to include("BlobResourceContents = Data.define")
      expect(code).to include("def initialize")
    end

    it "uses a custom class name when provided" do
      code = described_class.generate_from_file_definition(schema_path, definition_name, class_name)
      expect(code).to include("CustomBlob = Data.define")
      expect(code).to include("def initialize")
    end
  end

  describe ".generate_from_multiple_definitions" do
    let(:schema_path) { "spec/fixtures/schema.json" }
    let(:schema_json) { File.read(schema_path) }
    let(:definition_names) { ["BlobResourceContents", "TextContent"] }

    it "generates Ruby code from multiple definitions" do
      code = described_class.generate_from_multiple_definitions(schema_json, definition_names)
      expect(code).to include("BlobResourceContents = Data.define")
      expect(code).to include("TextContent = Data.define")
    end
  end

  describe ".generate_from_file_multiple_definitions" do
    let(:schema_path) { "spec/fixtures/schema.json" }
    let(:definition_names) { ["BlobResourceContents", "TextContent"] }

    it "reads a file and generates Ruby code from multiple definitions" do
      code = described_class.generate_from_file_multiple_definitions(schema_path, definition_names)
      expect(code).to include("BlobResourceContents = Data.define")
      expect(code).to include("TextContent = Data.define")
    end
  end

  describe ".list_definitions" do
    let(:schema_path) { "spec/fixtures/schema.json" }
    let(:schema_json) { File.read(schema_path) }

    it "returns a list of available definitions" do
      definitions = described_class.list_definitions(schema_json)
      expect(definitions).to be_an(Array)
      expect(definitions).not_to be_empty
      expect(definitions).to include("BlobResourceContents")
    end
  end

  describe ".list_definitions_from_file" do
    let(:schema_path) { "spec/fixtures/schema.json" }

    it "reads a file and returns a list of available definitions" do
      definitions = described_class.list_definitions_from_file(schema_path)
      expect(definitions).to be_an(Array)
      expect(definitions).not_to be_empty
      expect(definitions).to include("BlobResourceContents")
    end
  end
end
