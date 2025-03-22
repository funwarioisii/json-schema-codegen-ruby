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
end 