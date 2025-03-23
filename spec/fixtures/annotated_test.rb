# AnnotatedAnnotation クラスの型定義:
# - audience: any[] (配列) - Describes who the intended customer of this object or data is.
#   It can include multiple entries to indicate content useful for multiple audiences (e.g., `["user", "assistant"]`).
# - priority: number - Describes how important this data is for operating the server.
#   A value of 1 means "most important," and indicates that the data is
#   effectively required, while 0 means "least important," and indicates that
#   the data is entirely optional.

AnnotatedAnnotation = Data.define(:audience, :priority) do
  def initialize(audience: nil, priority: nil)
    unless audience.nil?
      raise TypeError, "audienceは配列である必要があります" unless audience.is_a?(Array)
    end
    validate_array_items(audience, "", "audience") unless audience.nil?
    unless priority.nil?
      raise TypeError, "priorityは数値である必要があります" unless priority.is_a?(Numeric)
    end
    raise ArgumentError, "priorityは0以上である必要があります" if priority < 0
    raise ArgumentError, "priorityは1以下である必要があります" if priority > 1
    super
  end

  private

  # 配列内の各アイテムの型を検証するヘルパーメソッド
  def validate_array_items(array, expected_type, array_name)
    type_check_method = case expected_type
    when "string" then ->(item) { item.is_a?(String) }
    when "integer" then ->(item) { item.is_a?(Integer) }
    when "number" then ->(item) { item.is_a?(Numeric) }
    when "boolean" then ->(item) { [true, false].include?(item) }
    when "array" then ->(item) { item.is_a?(Array) }
    when "object" then ->(item) { item.is_a?(Hash) }
    else ->(item) { true } # 不明な型は常にtrueを返す
    end

    type_error_message = case expected_type
    when "string" then "a String"
    when "integer" then "an Integer"
    when "number" then "a Numeric"
    when "boolean" then "a Boolean"
    when "array" then "an Array"
    when "object" then "a Hash"
    else "of the correct type"
    end

    array.each do |item|
      unless type_check_method.call(item)
        raise TypeError, "All items in #{array_name} must be #{type_error_message}"
      end
    end
  end

  # 配列内の数値アイテムの最小値を検証するヘルパーメソッド
  def validate_array_items_minimum(array, minimum, array_name)
    array.each do |item|
      if item < minimum
        raise ArgumentError, "Items in #{array_name} must be greater than or equal to #{minimum}"
      end
    end
  end

  # 配列内の数値アイテムの最大値を検証するヘルパーメソッド
  def validate_array_items_maximum(array, maximum, array_name)
    array.each do |item|
      if item > maximum
        raise ArgumentError, "Items in #{array_name} must be less than or equal to #{maximum}"
      end
    end
  end
end

# Base for objects that include optional annotations for the client. The client can use annotations to inform how objects are used or displayed
# Annotated クラスの型定義:
# - annotations: オブジェクト

Annotated = Data.define(:annotations) do
  def initialize(annotations: nil)
    unless annotations.nil?
      raise TypeError, "annotationsはHashである必要があります" unless annotations.is_a?(Hash)
      annotations = AnnotatedAnnotation.new(**annotations)
    end
    super
  end
end
