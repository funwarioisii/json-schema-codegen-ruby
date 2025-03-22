# JSON Schema Codegen Ruby

JSON SchemaからRubyのData.defineクラスを生成するライブラリです。

## インストール

```ruby
gem 'json_schema_codegen'
```

## 使用例

### ライブラリとして使用

```ruby
require 'json_schema_codegen'

# 文字列からJSON Schemaを読み込む
schema_json = <<~JSON
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "ユーザー名"
    },
    "age": {
      "type": "integer",
      "description": "年齢",
      "minimum": 0
    },
    "email": {
      "type": "string",
      "format": "email",
      "description": "メールアドレス"
    },
    "is_active": {
      "type": "boolean",
      "description": "アクティブかどうか"
    }
  },
  "required": [
    "name",
    "age",
    "email"
  ]
}
JSON

# Rubyコードを生成
ruby_code = JsonSchemaCodegen.generate(schema_json, "User")
puts ruby_code

# ファイルから生成する場合
ruby_code = JsonSchemaCodegen.generate_from_file("schema.json", "User")
```

### コマンドラインツールとして使用

```bash
# 基本的な使い方
$ json_schema_codegen schema.json

# 出力ファイルを指定
$ json_schema_codegen -o user.rb schema.json

# クラス名を指定
$ json_schema_codegen -c Customer schema.json
```

## 生成されるコード例

以下は生成されるRubyコードの例です：

```ruby
User = Data.define(:name, :age, :email, :is_active) do
  def initialize(name:, age:, email:, is_active: nil)
    raise TypeError, "name must be a String" unless name.is_a?(String)
    raise TypeError, "age must be an Integer" unless age.is_a?(Integer)
    raise ArgumentError, "age must be greater than or equal to 0" if age < 0
    raise TypeError, "email must be a String" unless email.is_a?(String)
    unless is_active.nil?
      raise TypeError, "is_active must be a Boolean" unless [true, false].include?(is_active)
    end
    super(name: name, age: age, email: email, is_active: is_active)
  end
end
```

## テスト

```bash
$ bundle exec rspec
```

## ライセンス

MITライセンスで提供されています。 