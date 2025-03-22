# frozen_string_literal: true

module JsonSchemaCodegen
  class Generator
    def initialize(schema, class_name)
      @schema = schema
      @class_name = class_name
    end

    def generate
      return "# JSONスキーマの型がobjectではありません" unless @schema["type"] == "object"

      properties = @schema["properties"] || {}
      required = @schema["required"] || []

      fields = properties.keys
      code = []

      # Data.defineクラス宣言
      code << "#{@class_name} = Data.define(:#{fields.join(', :')}) do"

      # コンストラクタの定義
      params = fields.map do |field|
        if required.include?(field)
          "#{field}:"
        else
          "#{field}: nil"
        end
      end.join(", ")

      code << "  def initialize(#{params})"

      # 型チェックと制約のバリデーション
      properties.each do |name, property|
        code << generate_validation(name, property, required.include?(name))
      end

      code << "    super(#{fields.map { |f| "#{f}: #{f}" }.join(', ')})"
      code << "  end"
      code << "end"

      code.join("\n")
    end

    private

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
          validations << "    raise ArgumentError, \"#{name} must be greater than or equal to #{property["minimum"]}\" if #{name} < #{property["minimum"]}"
        end
        if property["maximum"]
          validations << "    raise ArgumentError, \"#{name} must be less than or equal to #{property["maximum"]}\" if #{name} > #{property["maximum"]}"
        end
      end

      # 文字列の制約チェック
      if property["type"] == "string"
        if property["minLength"]
          validations << "    raise ArgumentError, \"#{name} must be at least #{property["minLength"]} characters\" if #{name}.length < #{property["minLength"]}"
        end
        if property["maxLength"]
          validations << "    raise ArgumentError, \"#{name} must be at most #{property["maxLength"]} characters\" if #{name}.length > #{property["maxLength"]}"
        end
        if property["pattern"]
          validations << "    raise ArgumentError, \"#{name} must match pattern #{property["pattern"]}\" unless #{name} =~ /#{property["pattern"]}/"
        end
      end

      # 配列の制約チェック
      if property["type"] == "array"
        if property["minItems"]
          validations << "    raise ArgumentError, \"#{name} must have at least #{property["minItems"]} items\" if #{name}.length < #{property["minItems"]}"
        end
        if property["maxItems"]
          validations << "    raise ArgumentError, \"#{name} must have at most #{property["maxItems"]} items\" if #{name}.length > #{property["maxItems"]}"
        end
      end

      validations.join("\n")
    end

    def generate_type_check(name, type, format = nil)
      case type
      when "string"
        "    raise TypeError, \"#{name} must be a String\" unless #{name}.is_a?(String)"
      when "integer"
        "    raise TypeError, \"#{name} must be an Integer\" unless #{name}.is_a?(Integer)"
      when "number"
        "    raise TypeError, \"#{name} must be a Numeric\" unless #{name}.is_a?(Numeric)"
      when "boolean"
        "    raise TypeError, \"#{name} must be a Boolean\" unless [true, false].include?(#{name})"
      when "array"
        "    raise TypeError, \"#{name} must be an Array\" unless #{name}.is_a?(Array)"
      when "object"
        "    raise TypeError, \"#{name} must be a Hash\" unless #{name}.is_a?(Hash)"
      else
        nil
      end
    end
  end
end 