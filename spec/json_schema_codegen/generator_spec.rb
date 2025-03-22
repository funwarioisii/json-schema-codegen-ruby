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
  
  describe "nested objects" do
    let(:schema) { JSON.parse(File.read("spec/fixtures/nested_object_schema.json")) }
    let(:class_name) { "Person" }

    it "generates classes for nested objects" do
      code = subject.generate
      expect(code).to include("Person = Data.define(:name, :address)")
      expect(code).to include("Address = Data.define(:street, :city, :zipcode)")
      expect(code).to include("def initialize(name:, address: nil)")
      expect(code).to include("address = Address.new(**address)")
    end

    it "properly validates nested objects" do
      code = subject.generate
      # コードを評価して実際のクラスを生成
      eval(code)

      # 正常なケース
      expect {
        Person.new(
          name: "山田太郎",
          address: {
            street: "桜通り1-2-3",
            city: "東京都",
            zipcode: "123-4567"
          }
        )
      }.not_to raise_error

      # ネストしたオブジェクトの型エラー
      expect {
        Person.new(
          name: "鈴木花子",
          address: "東京都渋谷区" # 文字列ではなくオブジェクトが必要
        )
      }.to raise_error(TypeError, "address must be a Hash")

      # ネストしたオブジェクトの必須フィールドエラー
      expect {
        Person.new(
          name: "佐藤次郎",
          address: {
            city: "大阪府"
            # streetが不足
          }
        )
      }.to raise_error(ArgumentError)
    end
  end

  describe "array items validation" do
    let(:schema) { JSON.parse(File.read("spec/fixtures/array_schema.json")) }
    let(:class_name) { "Post" }

    it "generates classes with array item validation" do
      code = subject.generate
      expect(code).to include("Post = Data.define(:name, :tags, :scores)")
      expect(code).to include("def initialize(name:, tags:, scores: nil)")
      expect(code).to include("validate_array_items(tags, \"string\", \"tags\")")
      expect(code).to include("validate_array_items(scores, \"integer\", \"scores\")")
    end

    it "properly validates array items" do
      code = subject.generate
      # コードを評価して実際のクラスを生成
      eval(code)

      # 正常なケース
      expect {
        Post.new(
          name: "ブログ記事",
          tags: ["Ruby", "JSON", "Schema"],
          scores: [85, 90, 75]
        )
      }.not_to raise_error

      # 配列要素の型エラー
      expect {
        Post.new(
          name: "ブログ記事",
          tags: ["Ruby", 123, "Schema"], # 数値が含まれている
          scores: [85, 90, 75]
        )
      }.to raise_error(TypeError, "All items in tags must be a String")

      # 配列要素の制約エラー
      expect {
        Post.new(
          name: "ブログ記事",
          tags: ["Ruby", "JSON"],
          scores: [85, 90, -5] # 負の値は許可されていない
        )
      }.to raise_error(ArgumentError, "Items in scores must be greater than or equal to 0")

      # 配列の長さ制約エラー
      expect {
        Post.new(
          name: "ブログ記事",
          tags: [], # 最低1つ必要
          scores: [85, 90]
        )
      }.to raise_error(ArgumentError, "tags must have at least 1 items")
    end
  end

  describe "enum validation" do
    let(:schema) { JSON.parse(File.read("spec/fixtures/enum_schema.json")) }
    let(:class_name) { "Task" }

    it "generates classes with enum validation" do
      code = subject.generate
      expect(code).to include("Task = Data.define(:name, :status, :priority)")
      expect(code).to include("def initialize(name:, status:, priority: nil)")
      expect(code).to include("validate_enum(status, [\"active\", \"inactive\", \"pending\"], \"status\")")
      expect(code).to include("validate_enum(priority, [1, 2, 3, 5, 8], \"priority\")")
    end

    it "properly validates enum values" do
      code = subject.generate
      # コードを評価して実際のクラスを生成
      eval(code)

      # 正常なケース
      expect {
        Task.new(
          name: "タスク1",
          status: "active",
          priority: 3
        )
      }.not_to raise_error

      # enumに含まれない値のエラー (文字列)
      expect {
        Task.new(
          name: "タスク2",
          status: "unknown", # 許可されていない値
          priority: 2
        )
      }.to raise_error(ArgumentError, "status must be one of: active, inactive, pending")

      # enumに含まれない値のエラー (数値)
      expect {
        Task.new(
          name: "タスク3",
          status: "active",
          priority: 4 # 許可されていない値
        )
      }.to raise_error(ArgumentError, "priority must be one of: 1, 2, 3, 5, 8")
    end
  end

  describe "anyOf and oneOf validation" do
    let(:schema) { JSON.parse(File.read("spec/fixtures/any_one_of_schema.json")) }
    let(:class_name) { "Payment" }

    it "generates classes with anyOf validation" do
      code = subject.generate
      expect(code).to include("Payment = Data.define(:id, :value, :payment)")
      expect(code).to include("def initialize(id:, value: nil, payment: nil)")
      expect(code).to include("validate_any_of(value") # anyOfの検証コード
    end

    it "properly validates anyOf values" do
      code = subject.generate
      # コードを評価して実際のクラスを生成
      eval(code)

      # 正常なケース（文字列）
      expect {
        Payment.new(
          id: "ABC123",
          value: "文字列の値"
        )
      }.not_to raise_error

      # 正常なケース（数値）
      expect {
        Payment.new(
          id: "ABC123",
          value: 12345
        )
      }.not_to raise_error

      # 正常なケース（ブール値）
      expect {
        Payment.new(
          id: "ABC123",
          value: true
        )
      }.not_to raise_error

      # anyOfに含まれない型のエラー
      expect {
        Payment.new(
          id: "ABC123",
          value: { key: "value" } # オブジェクトは許可されていない
        )
      }.to raise_error(ArgumentError, /value does not match any of the allowed schemas/)
    end

    it "properly validates oneOf values" do
      code = subject.generate
      eval(code)

      # 正常なケース（カード決済）
      expect {
        Payment.new(
          id: "ABC123",
          payment: {
            card_number: "1234567890123456",
            expiry: "12/25"
          }
        )
      }.not_to raise_error

      # 正常なケース（銀行振込）
      expect {
        Payment.new(
          id: "ABC123",
          payment: {
            bank_account: "123-456789",
            branch_code: "001"
          }
        )
      }.not_to raise_error

      # oneOfに含まれない構造のエラー
      expect {
        Payment.new(
          id: "ABC123",
          payment: {
            something_else: "invalid"
          }
        )
      }.to raise_error(ArgumentError, /payment does not match exactly one of the allowed schemas/)
      
      # 必須フィールドが不足しているエラー
      expect {
        Payment.new(
          id: "ABC123",
          payment: {
            card_number: "1234567890123456"
            # expiryが不足
          }
        )
      }.to raise_error(ArgumentError, /payment does not match exactly one of the allowed schemas/)
    end
  end

  describe "format validation" do
    let(:schema) { JSON.parse(File.read("spec/fixtures/format_schema.json")) }
    let(:class_name) { "Profile" }

    it "generates classes with format validation" do
      code = subject.generate
      expect(code).to include("Profile = Data.define(:id, :email, :website, :date_of_birth, :created_at, :ipv4, :ipv6)")
      expect(code).to include("def initialize(id:, email:, website: nil, date_of_birth: nil, created_at: nil, ipv4: nil, ipv6: nil)")
      expect(code).to include("validate_format(email, \"email\", \"email\")")
      expect(code).to include("validate_format(website, \"uri\", \"website\")")
      expect(code).to include("validate_format(date_of_birth, \"date\", \"date_of_birth\")")
    end

    it "properly validates format values" do
      code = subject.generate
      # コードを評価して実際のクラスを生成
      eval(code)

      # 正常なケース
      expect {
        Profile.new(
          id: "user123",
          email: "user@example.com",
          website: "https://example.com",
          date_of_birth: "1990-01-01",
          created_at: "2020-01-01T12:00:00Z",
          ipv4: "192.168.1.1",
          ipv6: "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
        )
      }.not_to raise_error

      # 不正なメールアドレス
      expect {
        Profile.new(
          id: "user123",
          email: "not-an-email"
        )
      }.to raise_error(ArgumentError, /email is not a valid email format/)

      # 不正なURI
      expect {
        Profile.new(
          id: "user123",
          email: "user@example.com",
          website: "not-a-url"
        )
      }.to raise_error(ArgumentError, /website is not a valid uri format/)

      # 不正な日付
      expect {
        Profile.new(
          id: "user123",
          email: "user@example.com",
          date_of_birth: "not-a-date"
        )
      }.to raise_error(ArgumentError, /date_of_birth is not a valid date format/)
    end
  end
end 