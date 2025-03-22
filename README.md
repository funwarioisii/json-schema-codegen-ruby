# JSON Schema Codegen Ruby

JSONスキーマからRubyのData.defineクラスを自動生成するジェネレーターです。

## 機能

- JSON Schemaから厳密な型チェックを行うRubyのData.defineクラスを生成
- 基本的なデータ型の検証（string, number, integer, boolean, array, object）
- ネストしたオブジェクト構造のサポート
- 制約条件のバリデーション（required, format, pattern, min/max値など）
- enum、anyOf、oneOfのサポート
- JSON Schemaの`definitions`セクションからクラス生成（複数定義対応）

## インストール

```bash
$ gem install json_schema_codegen
```

## 使用方法

### ライブラリとして使用する場合

```ruby
require 'json_schema_codegen'

# 文字列からコード生成
schema_json = '{"type": "object", "properties": {"name": {"type": "string"}}}'
ruby_code = JsonSchemaCodegen.generate(schema_json, 'User')

# ファイルからコード生成
ruby_code = JsonSchemaCodegen.generate_from_file('user_schema.json', 'User')

# 定義セクションからコード生成
ruby_code = JsonSchemaCodegen.generate_from_file_definition('schema.json', 'UserProfile')

# 複数の定義からコード生成
ruby_code = JsonSchemaCodegen.generate_from_file_multiple_definitions(
  'schema.json',
  ['UserProfile', 'UserPermissions']
)

# 定義一覧を取得
definitions = JsonSchemaCodegen.list_definitions_from_file('schema.json')
```

### コマンドラインから使用する場合

```bash
# 基本的な使用法
$ json_schema_codegen user_schema.json

# クラス名を指定
$ json_schema_codegen user_schema.json -c UserModel

# 出力ファイルを指定
$ json_schema_codegen user_schema.json -o user_model.rb

# 定義一覧を表示
$ json_schema_codegen schema.json -l

# 特定の定義からクラスを生成
$ json_schema_codegen schema.json -d UserProfile

# 複数の定義からクラスを生成
$ json_schema_codegen schema.json -m UserProfile,UserPermissions

# すべての定義からクラスを生成
$ json_schema_codegen schema.json -a
```

## 生成されるコードの例

JSONスキーマ:

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1
    },
    "age": {
      "type": "integer",
      "minimum": 0
    },
    "email": {
      "type": "string",
      "format": "email"
    }
  },
  "required": ["name", "email"]
}
```

生成されるRubyコード:

```ruby
User = Data.define(:name, :age, :email) do
  def initialize(name:, age: nil, email:)
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    raise ArgumentError, "nameは1文字以上である必要があります" if name.length < 1
    unless age.nil?
      raise TypeError, "ageは整数である必要があります" unless age.is_a?(Integer)
      raise ArgumentError, "ageは0以上である必要があります" if age < 0
    end
    raise TypeError, "emailは文字列である必要があります" unless email.is_a?(String)
    validate_format(email, "email", "email")
    super(name: name, age: age, email: email)
  end
  
  private

  # フォーマットを検証するヘルパーメソッド
  def validate_format(value, format, field_name)
    case format
    when "email"
      unless value =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
        raise ArgumentError, "#{field_name}は有効なメールアドレス形式ではありません"
      end
    end
  end
end
```

## ライセンス

MIT License

## 貢献

1. Forkする
2. ブランチを作成する (`git checkout -b my-new-feature`)
3. 変更をコミットする (`git commit -am 'Add some feature'`)
4. ブランチをPushする (`git push origin my-new-feature`)
5. Pull Requestを作成する 