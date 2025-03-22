# BlobResourceContents クラスの型定義:
# - blob: string (byte) - A base64-encoded string representing the binary data of the item.
# - mimeType: string - The MIME type of this resource, if known.
# - uri: string (uri) - The URI of this resource.

BlobResourceContents = Data.define(:blob, :mimeType, :uri) do
  def initialize(blob:, uri:, mimeType: nil)
    raise TypeError, "blobは文字列である必要があります" unless blob.is_a?(String)
    validate_format(blob, "byte", "blob")
    unless mimeType.nil?
      raise TypeError, "mimeTypeは文字列である必要があります" unless mimeType.is_a?(String)
    end
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri", "uri")
    super
  end

  private

  # フォーマットを検証するヘルパーメソッド
  def validate_format(value, format, field_name)
    case format
    when "email"
      unless /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i.match?(value)
        raise ArgumentError, "#{field_name}は有効なメールアドレス形式ではありません"
      end
    when "uri"
      begin
        require "uri"
        uri = URI.parse(value)
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          raise ArgumentError, "#{field_name}は有効なURI形式ではありません"
        end
      rescue URI::InvalidURIError
        raise ArgumentError, "#{field_name}は有効なURI形式ではありません"
      end
    when "date"
      begin
        require "date"
        Date.parse(value)
      rescue ArgumentError
        raise ArgumentError, "#{field_name}は有効な日付形式ではありません"
      end
    when "date-time"
      begin
        require "time"
        Time.parse(value)
      rescue ArgumentError
        raise ArgumentError, "#{field_name}は有効な日時形式ではありません"
      end
    when "ipv4"
      unless /\A(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\z/.match?(value)
        raise ArgumentError, "#{field_name}は有効なIPv4アドレスではありません"
      end
    when "ipv6"
      # 簡略化したIPv6チェック - より厳密な検証が必要な場合は拡張すべき
      unless value =~ /\A[\da-fA-F:]+\z/ && value.count(":") >= 2
        raise ArgumentError, "#{field_name}は有効なIPv6アドレスではありません"
      end
    end
  end
end
