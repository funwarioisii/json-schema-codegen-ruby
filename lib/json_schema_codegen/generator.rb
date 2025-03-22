# frozen_string_literal: true

module JsonSchemaCodegen
  class Generator
    def initialize(schema, class_name)
      @schema = schema
      @class_name = class_name
      @generated_classes = []
    end

    def generate
      return "# JSONスキーマの型がobjectではありません" unless @schema["type"] == "object"

      @generated_classes = []
      main_class = generate_class(@schema, @class_name)

      # メインクラスと追加のクラスを結合
      (@generated_classes + [main_class]).join("\n\n")
    end

    private

    def generate_class(schema, class_name)
      properties = schema["properties"] || {}
      required = schema["required"] || []

      fields = properties.keys
      code = []

      # クラスの説明コメントを追加
      if schema["description"]
        code << "# #{schema["description"]}"
      end

      # フィールドの型情報コメントを追加
      code << "# #{class_name} クラスの型定義:"
      properties.each do |name, property|
        type_info = property_type_description(name, property)
        code << "# - #{name}: #{type_info}"
      end

      # 空行を追加して読みやすさを向上
      code << ""

      # Data.defineクラス宣言
      code << "#{class_name} = Data.define(:#{fields.join(", :")}) do"

      # コンストラクタの定義
      params = fields.map do |field|
        if required.include?(field)
          "#{field}:"
        else
          "#{field}: nil"
        end
      end.join(", ")

      code << "  def initialize(#{params})"

      # ヘルパーメソッド使用フラグ
      has_array_with_items = properties.any? { |_, prop| prop["type"] == "array" && prop["items"] }
      has_enum = properties.any? { |_, prop| prop["enum"] }
      has_any_of = properties.any? { |_, prop| prop["anyOf"] }
      has_one_of = properties.any? { |_, prop| prop["oneOf"] }
      has_format = properties.any? { |_, prop| prop["format"] }

      # 型チェックと制約のバリデーション
      properties.each do |name, property|
        # ネストしたオブジェクトの処理
        if property["type"] == "object"
          nested_class_name = nested_class_name(class_name, name)
          @generated_classes << generate_class(property, nested_class_name)
          code << generate_nested_object_handling(name, nested_class_name, required.include?(name))
        else
          # 通常の型チェック（oneOfやanyOf以外）
          if !property["anyOf"] && !property["oneOf"]
            code << generate_validation(name, property, required.include?(name))
          end

          # フォーマット検証
          if property["format"] && property["type"] == "string"
            format = property["format"]
            code << if required.include?(name)
              "    validate_format(#{name}, \"#{format}\", \"#{name}\")"
            else
              "    validate_format(#{name}, \"#{format}\", \"#{name}\") unless #{name}.nil?"
            end
          end

          # enumの検証
          if property["enum"]
            enum_values = property["enum"].map do |val|
              val.is_a?(String) ? "\"#{val}\"" : val
            end
            code << if required.include?(name)
              "    validate_enum(#{name}, [#{enum_values.join(", ")}], \"#{name}\")"
            else
              "    validate_enum(#{name}, [#{enum_values.join(", ")}], \"#{name}\") unless #{name}.nil?"
            end
          end

          # anyOf の検証
          if property["anyOf"]
            schemas = property["anyOf"].map { |schema| schema.to_json }
            code << if required.include?(name)
              "    validate_any_of(#{name}, [#{schemas.map { |s| "JSON.parse('#{s}')" }.join(", ")}], \"#{name}\")"
            else
              "    validate_any_of(#{name}, [#{schemas.map { |s| "JSON.parse('#{s}')" }.join(", ")}], \"#{name}\") unless #{name}.nil?"
            end
          end

          # oneOf の検証
          if property["oneOf"]
            schemas = property["oneOf"].map { |schema| schema.to_json }
            code << if required.include?(name)
              "    validate_one_of(#{name}, [#{schemas.map { |s| "JSON.parse('#{s}')" }.join(", ")}], \"#{name}\")"
            else
              "    validate_one_of(#{name}, [#{schemas.map { |s| "JSON.parse('#{s}')" }.join(", ")}], \"#{name}\") unless #{name}.nil?"
            end
          end

          # 配列アイテムの検証
          if property["type"] == "array" && property["items"]
            items_type = property["items"]["type"]
            if required.include?(name)
              code << "    validate_array_items(#{name}, \"#{items_type}\", \"#{name}\")"

              # 数値の制約がある場合
              if items_type == "integer" || items_type == "number"
                if property["items"]["minimum"]
                  code << "    validate_array_items_minimum(#{name}, #{property["items"]["minimum"]}, \"#{name}\")"
                end
                if property["items"]["maximum"]
                  code << "    validate_array_items_maximum(#{name}, #{property["items"]["maximum"]}, \"#{name}\")"
                end
              end
            else
              code << "    validate_array_items(#{name}, \"#{items_type}\", \"#{name}\") unless #{name}.nil?"

              # 数値の制約がある場合
              if items_type == "integer" || items_type == "number"
                if property["items"]["minimum"]
                  code << "    validate_array_items_minimum(#{name}, #{property["items"]["minimum"]}, \"#{name}\") unless #{name}.nil?"
                end
                if property["items"]["maximum"]
                  code << "    validate_array_items_maximum(#{name}, #{property["items"]["maximum"]}, \"#{name}\") unless #{name}.nil?"
                end
              end
            end
          end
        end
      end

      code << "    super(#{fields.map { |f| "#{f}: #{f}" }.join(", ")})"
      code << "  end"

      # ヘルパーメソッドを追加
      helpers = []

      # 配列検証用のヘルパーメソッドを追加
      if has_array_with_items
        helpers << add_array_validation_helpers
      end

      # enum検証用のヘルパーメソッドを追加
      if has_enum
        helpers << add_enum_validation_helper
      end

      # anyOf検証用のヘルパーメソッドを追加
      if has_any_of
        helpers << add_any_of_validation_helper
      end

      # oneOf検証用のヘルパーメソッドを追加
      if has_one_of
        helpers << add_one_of_validation_helper
      end

      # フォーマット検証用のヘルパーメソッドを追加
      if has_format
        helpers << add_format_validation_helper
      end

      if !helpers.empty?
        code << "  private"
        code.concat(helpers)
      end

      code << "end"

      code.join("\n")
    end

    def add_array_validation_helpers
      [
        "",
        "  # 配列内の各アイテムの型を検証するヘルパーメソッド",
        "  def validate_array_items(array, expected_type, array_name)",
        "    type_check_method = case expected_type",
        "                        when \"string\"  then ->(item) { item.is_a?(String) }",
        "                        when \"integer\" then ->(item) { item.is_a?(Integer) }",
        "                        when \"number\"  then ->(item) { item.is_a?(Numeric) }",
        "                        when \"boolean\" then ->(item) { [true, false].include?(item) }",
        "                        when \"array\"   then ->(item) { item.is_a?(Array) }",
        "                        when \"object\"  then ->(item) { item.is_a?(Hash) }",
        "                        else ->(item) { true } # 不明な型は常にtrueを返す",
        "                        end",
        "                        ",
        "    type_error_message = case expected_type",
        "                        when \"string\"  then \"a String\"",
        "                        when \"integer\" then \"an Integer\"",
        "                        when \"number\"  then \"a Numeric\"",
        "                        when \"boolean\" then \"a Boolean\"",
        "                        when \"array\"   then \"an Array\"",
        "                        when \"object\"  then \"a Hash\"",
        "                        else \"of the correct type\"",
        "                        end",
        "                        ",
        "    array.each do |item|",
        "      unless type_check_method.call(item)",
        "        raise TypeError, \"All items in \#{array_name} must be \#{type_error_message}\"",
        "      end",
        "    end",
        "  end",
        "  ",
        "  # 配列内の数値アイテムの最小値を検証するヘルパーメソッド",
        "  def validate_array_items_minimum(array, minimum, array_name)",
        "    array.each do |item|",
        "      if item < minimum",
        "        raise ArgumentError, \"Items in \#{array_name} must be greater than or equal to \#{minimum}\"",
        "      end",
        "    end",
        "  end",
        "  ",
        "  # 配列内の数値アイテムの最大値を検証するヘルパーメソッド",
        "  def validate_array_items_maximum(array, maximum, array_name)",
        "    array.each do |item|",
        "      if item > maximum",
        "        raise ArgumentError, \"Items in \#{array_name} must be less than or equal to \#{maximum}\"",
        "      end",
        "    end",
        "  end"
      ]
    end

    def add_enum_validation_helper
      [
        "",
        "  # enumの値を検証するヘルパーメソッド",
        "  def validate_enum(value, allowed_values, field_name)",
        "    unless allowed_values.include?(value)",
        "      formatted_values = allowed_values.map(&:to_s).join(\", \")",
        "      raise ArgumentError, \"\#{field_name}は次のいずれかである必要があります: \#{formatted_values}\"",
        "    end",
        "  end"
      ]
    end

    def add_any_of_validation_helper
      [
        "",
        "  # anyOfの値を検証するヘルパーメソッド",
        "  def validate_any_of(value, schemas, field_name)",
        "    # どれか1つのスキーマに一致すればOK",
        "    return if schemas.any? { |schema| validate_schema(value, schema) }",
        "    raise ArgumentError, \"\#{field_name}は許可されているスキーマのいずれにも一致しません\"",
        "  end",
        "",
        "  # 値がスキーマに一致するかを検証するヘルパーメソッド",
        "  def validate_schema(value, schema)",
        "    # 基本的な型チェック",
        "    if schema[\"type\"]",
        "      case schema[\"type\"]",
        "      when \"string\"",
        "        return false unless value.is_a?(String)",
        "      when \"integer\"",
        "        return false unless value.is_a?(Integer)",
        "      when \"number\"",
        "        return false unless value.is_a?(Numeric)",
        "      when \"boolean\"",
        "        return false unless [true, false].include?(value)",
        "      when \"array\"",
        "        return false unless value.is_a?(Array)",
        "      when \"object\"",
        "        return false unless value.is_a?(Hash)",
        "        # オブジェクトの場合は必須プロパティのチェック",
        "        if schema[\"required\"]",
        "          schema[\"required\"].each do |req_prop|",
        "            return false unless value.key?(req_prop.to_sym) || value.key?(req_prop)",
        "          end",
        "        end",
        "      end",
        "    end",
        "",
        "    # 他の制約も検証できるように拡張可能",
        "    # ここではシンプルに型チェックのみ",
        "",
        "    true # すべての検証をパス",
        "  end"
      ]
    end

    def add_one_of_validation_helper
      [
        "",
        "  # oneOfの値を検証するヘルパーメソッド",
        "  def validate_one_of(value, schemas, field_name)",
        "    # ちょうど1つのスキーマに一致する必要がある",
        "    matching_count = schemas.count { |schema| validate_schema(value, schema) }",
        "    if matching_count != 1",
        "      raise ArgumentError, \"\#{field_name}は許可されたスキーマのうちちょうど1つと一致する必要があります\"",
        "    end",
        "  end"
      ]
    end

    def add_format_validation_helper
      [
        "",
        "  # フォーマットを検証するヘルパーメソッド",
        "  def validate_format(value, format, field_name)",
        "    case format",
        "    when \"email\"",
        "      unless value =~ /\\A[\\w+\\-.]+@[a-z\\d\\-.]+\\.[a-z]+\\z/i",
        "        raise ArgumentError, \"\#{field_name}は有効なメールアドレス形式ではありません\"",
        "      end",
        "    when \"uri\"",
        "      begin",
        "        require 'uri'",
        "        uri = URI.parse(value)",
        "        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)",
        "          raise ArgumentError, \"\#{field_name}は有効なURI形式ではありません\"",
        "        end",
        "      rescue URI::InvalidURIError",
        "        raise ArgumentError, \"\#{field_name}は有効なURI形式ではありません\"",
        "      end",
        "    when \"date\"",
        "      begin",
        "        require 'date'",
        "        Date.parse(value)",
        "      rescue ArgumentError",
        "        raise ArgumentError, \"\#{field_name}は有効な日付形式ではありません\"",
        "      end",
        "    when \"date-time\"",
        "      begin",
        "        require 'time'",
        "        Time.parse(value)",
        "      rescue ArgumentError",
        "        raise ArgumentError, \"\#{field_name}は有効な日時形式ではありません\"",
        "      end",
        "    when \"ipv4\"",
        "      unless value =~ /\\A(?:(?:25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\\.){3}(?:25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\\z/",
        "        raise ArgumentError, \"\#{field_name}は有効なIPv4アドレスではありません\"",
        "      end",
        "    when \"ipv6\"",
        "      # 簡略化したIPv6チェック - より厳密な検証が必要な場合は拡張すべき",
        "      unless value =~ /\\A[\\da-fA-F:]+\\z/ && value.count(':') >= 2",
        "        raise ArgumentError, \"\#{field_name}は有効なIPv6アドレスではありません\"",
        "      end",
        "    end",
        "  end"
      ]
    end

    def class_name_for_property(property_name)
      # 複数形を単数形に変換するシンプルなルール
      singular_name = if property_name.end_with?("s") && !property_name.end_with?("ss")
        property_name.chomp("s")
      elsif property_name.end_with?("ies")
        property_name.sub(/ies$/, "y")
      elsif property_name.end_with?("es") && !property_name.end_with?("sses")
        property_name.chomp("es")
      else
        property_name
      end

      # キャメルケースに変換
      singular_name.split("_").map(&:capitalize).join
    end

    # 親クラス名とプロパティ名からネストしたクラスの名前を生成
    def nested_class_name(parent_class, property_name)
      # 親クラス名とプロパティの組み合わせでより明確な名前を作成
      "#{parent_class}#{class_name_for_property(property_name)}"
    end

    def generate_nested_object_handling(name, class_name, required)
      if required
        [
          "    raise TypeError, \"#{name}はHashである必要があります\" unless #{name}.is_a?(Hash)",
          "    #{name} = #{class_name}.new(**#{name})"
        ].join("\n")
      else
        [
          "    unless #{name}.nil?",
          "      raise TypeError, \"#{name}はHashである必要があります\" unless #{name}.is_a?(Hash)",
          "      #{name} = #{class_name}.new(**#{name})",
          "    end"
        ].join("\n")
      end
    end

    def generate_validation(name, property, required)
      validations = []

      if required
        type_check = generate_type_check(name, property["type"], property["format"])
        validations << type_check if type_check
      else
        nil_check = "unless #{name}.nil?"
        type_check = generate_type_check(name, property["type"], property["format"])
        validations << "    #{nil_check}\n      #{type_check}\n    end" if type_check
      end

      # 数値の制約チェック
      if property["type"] == "integer" || property["type"] == "number"
        if property["minimum"]
          validations << "    raise ArgumentError, \"#{name}は#{property["minimum"]}以上である必要があります\" if #{name} < #{property["minimum"]}"
        end
        if property["maximum"]
          validations << "    raise ArgumentError, \"#{name}は#{property["maximum"]}以下である必要があります\" if #{name} > #{property["maximum"]}"
        end
      end

      # 文字列の長さチェック
      if property["type"] == "string"
        if property["minLength"]
          validations << "    raise ArgumentError, \"#{name}は#{property["minLength"]}文字以上である必要があります\" if #{name}.length < #{property["minLength"]}"
        end
        if property["maxLength"]
          validations << "    raise ArgumentError, \"#{name}は#{property["maxLength"]}文字以下である必要があります\" if #{name}.length > #{property["maxLength"]}"
        end
        if property["pattern"]
          validations << "    raise ArgumentError, \"#{name}は指定されたパターンに一致しません\" unless #{name} =~ /#{property["pattern"]}/i"
        end
      end

      # 配列の制約チェック
      if property["type"] == "array"
        if property["minItems"]
          validations << "    raise ArgumentError, \"#{name}は最低#{property["minItems"]}個の要素が必要です\" if #{name}.length < #{property["minItems"]}"
        end
        if property["maxItems"]
          validations << "    raise ArgumentError, \"#{name}は最大#{property["maxItems"]}個までの要素が許可されています\" if #{name}.length > #{property["maxItems"]}"
        end
      end

      validations.join("\n")
    end

    def generate_type_check(name, type, format = nil)
      case type
      when "string"
        "    raise TypeError, \"#{name}は文字列である必要があります\" unless #{name}.is_a?(String)"
      when "integer"
        "    raise TypeError, \"#{name}は整数である必要があります\" unless #{name}.is_a?(Integer)"
      when "number"
        "    raise TypeError, \"#{name}は数値である必要があります\" unless #{name}.is_a?(Numeric)"
      when "boolean"
        "    raise TypeError, \"#{name}は真偽値である必要があります\" unless [true, false].include?(#{name})"
      when "array"
        "    raise TypeError, \"#{name}は配列である必要があります\" unless #{name}.is_a?(Array)"
      when "object"
        "    raise TypeError, \"#{name}はHashである必要があります\" unless #{name}.is_a?(Hash)"
      end
    end

    # プロパティの型情報を人間が読みやすい形式で返す
    def property_type_description(name, property)
      if property["anyOf"]
        types = property["anyOf"].map { |p| p["type"] || "オブジェクト" }.uniq
        "#{types.join(" または ")}#{property["description"] ? " - " + property["description"] : ""}"
      elsif property["oneOf"]
        "oneOf パターン#{property["description"] ? " - " + property["description"] : ""}"
      elsif property["enum"]
        values = property["enum"].map { |v| v.is_a?(String) ? "\"#{v}\"" : v.to_s }
        "#{property["type"] || "any"} (#{values.join(", ")})#{property["description"] ? " - " + property["description"] : ""}"
      elsif property["type"] == "array" && property["items"]
        item_type = property["items"]["type"] || "any"
        "#{item_type}[] (配列)#{property["description"] ? " - " + property["description"] : ""}"
      elsif property["type"] == "object"
        "オブジェクト#{property["description"] ? " - " + property["description"] : ""}"
      else
        "#{property["type"] || "any"}#{property["format"] ? " (#{property["format"]})" : ""}#{property["description"] ? " - " + property["description"] : ""}"
      end
    end
  end
end
