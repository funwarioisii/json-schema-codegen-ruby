# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonSchemaCodegen::Generator do
  let(:schema) { JSON.parse(File.read("spec/fixtures/user_schema.json")) }
  let(:class_name) { "User" }

  subject { described_class.new(schema, class_name) }

  describe "#generate" do
    it "generates a valid Ruby class" do
      code = subject.generate
      expect(code).to include("User = Data.define(:name, :age, :email, :is_active)")
      expect(code).to include("def initialize(name:, age:, email:, is_active: nil)")
      expect(code).to include("raise TypeError, \"name must be a String\"")
      expect(code).to include("raise TypeError, \"age must be an Integer\"")
      expect(code).to include("raise TypeError, \"email must be a String\"")
      expect(code).to include("raise ArgumentError, \"age must be greater than or equal to 0\"")
    end

    it "generates a class that validates input types" do
      code = subject.generate
      # コードを評価して実際のクラスを生成
      eval(code)

      # 正常なケース
      expect {
        User.new(name: "花子", age: 25, email: "hanako@example.com")
      }.not_to raise_error

      # 型エラーのケース
      expect {
        User.new(name: "次郎", age: "35", email: "jiro@example.com")
      }.to raise_error(TypeError, "age must be an Integer")

      # 値の制約エラーのケース
      expect {
        User.new(name: "三郎", age: -1, email: "saburo@example.com")
      }.to raise_error(ArgumentError, "age must be greater than or equal to 0")
    end
  end
end 