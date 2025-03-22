# BlobResourceContents クラスの型定義:
# - blob: string (byte) - A base64-encoded string representing the binary data of the item.
# - mimeType: string - The MIME type of this resource, if known.
# - uri: string (uri) - The URI of this resource.

BlobResourceContents = Data.define(:blob, :mimeType, :uri) do
  def initialize(blob:, mimeType: nil, uri:)
    raise TypeError, "blobは文字列である必要があります" unless blob.is_a?(String)
    validate_format(blob, "byte", "blob")
    unless mimeType.nil?
          raise TypeError, "mimeTypeは文字列である必要があります" unless mimeType.is_a?(String)
    end
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri", "uri")
    super(blob: blob, mimeType: mimeType, uri: uri)
  end
  private

  # フォーマットを検証するヘルパーメソッド
  def validate_format(value, format, field_name)
    case format
    when "email"
      unless value =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
        raise ArgumentError, "#{field_name}は有効なメールアドレス形式ではありません"
      end
    when "uri"
      begin
        require 'uri'
        uri = URI.parse(value)
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          raise ArgumentError, "#{field_name}は有効なURI形式ではありません"
        end
      rescue URI::InvalidURIError
        raise ArgumentError, "#{field_name}は有効なURI形式ではありません"
      end
    when "date"
      begin
        require 'date'
        Date.parse(value)
      rescue ArgumentError
        raise ArgumentError, "#{field_name}は有効な日付形式ではありません"
      end
    when "date-time"
      begin
        require 'time'
        Time.parse(value)
      rescue ArgumentError
        raise ArgumentError, "#{field_name}は有効な日時形式ではありません"
      end
    when "ipv4"
      unless value =~ /\A(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\z/
        raise ArgumentError, "#{field_name}は有効なIPv4アドレスではありません"
      end
    when "ipv6"
      # 簡略化したIPv6チェック - より厳密な検証が必要な場合は拡張すべき
      unless value =~ /\A[\da-fA-F:]+\z/ && value.count(':') >= 2
        raise ArgumentError, "#{field_name}は有効なIPv6アドレスではありません"
      end
    end
  end
end

# TextContentAnnotation クラスの型定義:
# - audience: any[] (配列) - Describes who the intended customer of this object or data is.

It can include multiple entries to indicate content useful for multiple audiences (e.g., `["user", "assistant"]`).
# - priority: number - Describes how important this data is for operating the server.

A value of 1 means "most important," and indicates that the data is
effectively required, while 0 means "least important," and indicates that
the data is entirely optional.

TextContentAnnotation = Data.define(:audience, :priority) do
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
    super(audience: audience, priority: priority)
  end
  private

  # 配列内の各アイテムの型を検証するヘルパーメソッド
  def validate_array_items(array, expected_type, array_name)
    type_check_method = case expected_type
                        when "string"  then ->(item) { item.is_a?(String) }
                        when "integer" then ->(item) { item.is_a?(Integer) }
                        when "number"  then ->(item) { item.is_a?(Numeric) }
                        when "boolean" then ->(item) { [true, false].include?(item) }
                        when "array"   then ->(item) { item.is_a?(Array) }
                        when "object"  then ->(item) { item.is_a?(Hash) }
                        else ->(item) { true } # 不明な型は常にtrueを返す
                        end
                        
    type_error_message = case expected_type
                        when "string"  then "a String"
                        when "integer" then "an Integer"
                        when "number"  then "a Numeric"
                        when "boolean" then "a Boolean"
                        when "array"   then "an Array"
                        when "object"  then "a Hash"
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

# Text provided to or from an LLM.
# TextContent クラスの型定義:
# - annotations: オブジェクト
# - text: string - The text content of the message.
# - type: string

TextContent = Data.define(:annotations, :text, :type) do
  def initialize(annotations: nil, text:, type:)
    unless annotations.nil?
      raise TypeError, "annotationsはHashである必要があります" unless annotations.is_a?(Hash)
      annotations = TextContentAnnotation.new(**annotations)
    end
    raise TypeError, "textは文字列である必要があります" unless text.is_a?(String)
    raise TypeError, "typeは文字列である必要があります" unless type.is_a?(String)
    super(annotations: annotations, text: text, type: type)
  end
end