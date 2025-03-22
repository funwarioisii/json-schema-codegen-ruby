# AnnotatedAnnotation クラスの型定義:
# - audience: any[] (配列) - Describes who the intended customer of this object or data is.

It can include multiple entries to indicate content useful for multiple audiences (e.g., `["user", "assistant"]`).
# - priority: number - Describes how important this data is for operating the server.

A value of 1 means "most important," and indicates that the data is
effectively required, while 0 means "least important," and indicates that
the data is entirely optional.

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

# Base for objects that include optional annotations for the client. The client can use annotations to inform how objects are used or displayed
# Annotated クラスの型定義:
# - annotations: オブジェクト

Annotated = Data.define(:annotations) do
  def initialize(annotations: nil)
    unless annotations.nil?
      raise TypeError, "annotationsはHashである必要があります" unless annotations.is_a?(Hash)
      annotations = AnnotatedAnnotation.new(**annotations)
    end
    super(annotations: annotations)
  end
end

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

# CallToolRequestParamArgument クラスの型定義:

CallToolRequestParamArgument = Data.define(:) do
  def initialize()
    super()
  end
end

# CallToolRequestParam クラスの型定義:
# - arguments: オブジェクト
# - name: string

CallToolRequestParam = Data.define(:arguments, :name) do
  def initialize(arguments: nil, name:)
    unless arguments.nil?
      raise TypeError, "argumentsはHashである必要があります" unless arguments.is_a?(Hash)
      arguments = CallToolRequestParamArgument.new(**arguments)
    end
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    super(arguments: arguments, name: name)
  end
end

# Used by the client to invoke a tool provided by the server.
# CallToolRequest クラスの型定義:
# - method: string
# - params: オブジェクト

CallToolRequest = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = CallToolRequestParam.new(**params)
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# CallToolResultMeta クラスの型定義:

CallToolResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# The server's response to a tool call.

Any errors that originate from the tool SHOULD be reported inside the result
object, with `isError` set to true, _not_ as an MCP protocol-level error
response. Otherwise, the LLM would not be able to see that an error occurred
and self-correct.

However, any errors in _finding_ the tool, an error indicating that the
server does not support tool calls, or any other exceptional conditions,
should be reported as an MCP error response.
# CallToolResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - content: any[] (配列)
# - isError: boolean - Whether the tool call ended in an error.

If not set, this is assumed to be false (the call was successful).

CallToolResult = Data.define(:_meta, :content, :isError) do
  def initialize(_meta: nil, content:, isError: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = CallToolResultMeta.new(**_meta)
    end
    raise TypeError, "contentは配列である必要があります" unless content.is_a?(Array)
    validate_array_items(content, "", "content")
    unless isError.nil?
          raise TypeError, "isErrorは真偽値である必要があります" unless [true, false].include?(isError)
    end
    super(_meta: _meta, content: content, isError: isError)
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

# CancelledNotificationParam クラスの型定義:
# - reason: string - An optional string describing the reason for the cancellation. This MAY be logged or presented to the user.
# - requestId: any - The ID of the request to cancel.

This MUST correspond to the ID of a request previously issued in the same direction.

CancelledNotificationParam = Data.define(:reason, :requestId) do
  def initialize(reason: nil, requestId:)
    unless reason.nil?
          raise TypeError, "reasonは文字列である必要があります" unless reason.is_a?(String)
    end

    super(reason: reason, requestId: requestId)
  end
end

# This notification can be sent by either side to indicate that it is cancelling a previously-issued request.

The request SHOULD still be in-flight, but due to communication latency, it is always possible that this notification MAY arrive after the request has already finished.

This notification indicates that the result will be unused, so any associated processing SHOULD cease.

A client MUST NOT attempt to cancel its `initialize` request.
# CancelledNotification クラスの型定義:
# - method: string
# - params: オブジェクト

CancelledNotification = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = CancelledNotificationParam.new(**params)
    super(method: method, params: params)
  end
end

# Experimental, non-standard capabilities that the client supports.
# ClientCapabilitiesExperimental クラスの型定義:

ClientCapabilitiesExperimental = Data.define(:) do
  def initialize()
    super()
  end
end

# Present if the client supports listing roots.
# ClientCapabilitiesRoot クラスの型定義:
# - listChanged: boolean - Whether the client supports notifications for changes to the roots list.

ClientCapabilitiesRoot = Data.define(:listChanged) do
  def initialize(listChanged: nil)
    unless listChanged.nil?
          raise TypeError, "listChangedは真偽値である必要があります" unless [true, false].include?(listChanged)
    end
    super(listChanged: listChanged)
  end
end

# Present if the client supports sampling from an LLM.
# ClientCapabilitiesSampling クラスの型定義:

ClientCapabilitiesSampling = Data.define(:) do
  def initialize()
    super()
  end
end

# Capabilities a client may support. Known capabilities are defined here, in this schema, but this is not a closed set: any client can define its own, additional capabilities.
# ClientCapabilities クラスの型定義:
# - experimental: オブジェクト - Experimental, non-standard capabilities that the client supports.
# - roots: オブジェクト - Present if the client supports listing roots.
# - sampling: オブジェクト - Present if the client supports sampling from an LLM.

ClientCapabilities = Data.define(:experimental, :roots, :sampling) do
  def initialize(experimental: nil, roots: nil, sampling: nil)
    unless experimental.nil?
      raise TypeError, "experimentalはHashである必要があります" unless experimental.is_a?(Hash)
      experimental = ClientCapabilitiesExperimental.new(**experimental)
    end
    unless roots.nil?
      raise TypeError, "rootsはHashである必要があります" unless roots.is_a?(Hash)
      roots = ClientCapabilitiesRoot.new(**roots)
    end
    unless sampling.nil?
      raise TypeError, "samplingはHashである必要があります" unless sampling.is_a?(Hash)
      sampling = ClientCapabilitiesSampling.new(**sampling)
    end
    super(experimental: experimental, roots: roots, sampling: sampling)
  end
end

# JSONスキーマの型がobjectではありません

# JSONスキーマの型がobjectではありません

# JSONスキーマの型がobjectではありません

# The argument's information
# CompleteRequestParamArgument クラスの型定義:
# - name: string - The name of the argument
# - value: string - The value of the argument to use for completion matching.

CompleteRequestParamArgument = Data.define(:name, :value) do
  def initialize(name:, value:)
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    raise TypeError, "valueは文字列である必要があります" unless value.is_a?(String)
    super(name: name, value: value)
  end
end

# CompleteRequestParam クラスの型定義:
# - argument: オブジェクト - The argument's information
# - ref: オブジェクト

CompleteRequestParam = Data.define(:argument, :ref) do
  def initialize(argument:, ref:)
    raise TypeError, "argumentはHashである必要があります" unless argument.is_a?(Hash)
    argument = CompleteRequestParamArgument.new(**argument)
    validate_any_of(ref, [JSON.parse('{"$ref":"#/definitions/PromptReference"}'), JSON.parse('{"$ref":"#/definitions/ResourceReference"}')], "ref")
    super(argument: argument, ref: ref)
  end
  private

  # anyOfの値を検証するヘルパーメソッド
  def validate_any_of(value, schemas, field_name)
    # どれか1つのスキーマに一致すればOK
    return if schemas.any? { |schema| validate_schema(value, schema) }
    raise ArgumentError, "#{field_name}は許可されているスキーマのいずれにも一致しません"
  end

  # 値がスキーマに一致するかを検証するヘルパーメソッド
  def validate_schema(value, schema)
    # 基本的な型チェック
    if schema["type"]
      case schema["type"]
      when "string"
        return false unless value.is_a?(String)
      when "integer"
        return false unless value.is_a?(Integer)
      when "number"
        return false unless value.is_a?(Numeric)
      when "boolean"
        return false unless [true, false].include?(value)
      when "array"
        return false unless value.is_a?(Array)
      when "object"
        return false unless value.is_a?(Hash)
        # オブジェクトの場合は必須プロパティのチェック
        if schema["required"]
          schema["required"].each do |req_prop|
            return false unless value.key?(req_prop.to_sym) || value.key?(req_prop)
          end
        end
      end
    end

    # 他の制約も検証できるように拡張可能
    # ここではシンプルに型チェックのみ

    true # すべての検証をパス
  end
end

# A request from the client to the server, to ask for completion options.
# CompleteRequest クラスの型定義:
# - method: string
# - params: オブジェクト

CompleteRequest = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = CompleteRequestParam.new(**params)
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# CompleteResultMeta クラスの型定義:

CompleteResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# CompleteResultCompletion クラスの型定義:
# - hasMore: boolean - Indicates whether there are additional completion options beyond those provided in the current response, even if the exact total is unknown.
# - total: integer - The total number of completion options available. This can exceed the number of values actually sent in the response.
# - values: string[] (配列) - An array of completion values. Must not exceed 100 items.

CompleteResultCompletion = Data.define(:hasMore, :total, :values) do
  def initialize(hasMore: nil, total: nil, values:)
    unless hasMore.nil?
          raise TypeError, "hasMoreは真偽値である必要があります" unless [true, false].include?(hasMore)
    end
    unless total.nil?
          raise TypeError, "totalは整数である必要があります" unless total.is_a?(Integer)
    end
    raise TypeError, "valuesは配列である必要があります" unless values.is_a?(Array)
    validate_array_items(values, "string", "values")
    super(hasMore: hasMore, total: total, values: values)
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

# The server's response to a completion/complete request
# CompleteResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - completion: オブジェクト

CompleteResult = Data.define(:_meta, :completion) do
  def initialize(_meta: nil, completion:)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = CompleteResultMeta.new(**_meta)
    end
    raise TypeError, "completionはHashである必要があります" unless completion.is_a?(Hash)
    completion = CompleteResultCompletion.new(**completion)
    super(_meta: _meta, completion: completion)
  end
end

# Optional metadata to pass through to the LLM provider. The format of this metadata is provider-specific.
# CreateMessageRequestParamMetadata クラスの型定義:

CreateMessageRequestParamMetadata = Data.define(:) do
  def initialize()
    super()
  end
end

# CreateMessageRequestParam クラスの型定義:
# - includeContext: string ("allServers", "none", "thisServer") - A request to include context from one or more MCP servers (including the caller), to be attached to the prompt. The client MAY ignore this request.
# - maxTokens: integer - The maximum number of tokens to sample, as requested by the server. The client MAY choose to sample fewer tokens than requested.
# - messages: any[] (配列)
# - metadata: オブジェクト - Optional metadata to pass through to the LLM provider. The format of this metadata is provider-specific.
# - modelPreferences: any - The server's preferences for which model to select. The client MAY ignore these preferences.
# - stopSequences: string[] (配列)
# - systemPrompt: string - An optional system prompt the server wants to use for sampling. The client MAY modify or omit this prompt.
# - temperature: number

CreateMessageRequestParam = Data.define(:includeContext, :maxTokens, :messages, :metadata, :modelPreferences, :stopSequences, :systemPrompt, :temperature) do
  def initialize(includeContext: nil, maxTokens:, messages:, metadata: nil, modelPreferences: nil, stopSequences: nil, systemPrompt: nil, temperature: nil)
    unless includeContext.nil?
          raise TypeError, "includeContextは文字列である必要があります" unless includeContext.is_a?(String)
    end
    validate_enum(includeContext, ["allServers", "none", "thisServer"], "includeContext") unless includeContext.nil?
    raise TypeError, "maxTokensは整数である必要があります" unless maxTokens.is_a?(Integer)
    raise TypeError, "messagesは配列である必要があります" unless messages.is_a?(Array)
    validate_array_items(messages, "", "messages")
    unless metadata.nil?
      raise TypeError, "metadataはHashである必要があります" unless metadata.is_a?(Hash)
      metadata = CreateMessageRequestParamMetadata.new(**metadata)
    end

    unless stopSequences.nil?
          raise TypeError, "stopSequencesは配列である必要があります" unless stopSequences.is_a?(Array)
    end
    validate_array_items(stopSequences, "string", "stopSequences") unless stopSequences.nil?
    unless systemPrompt.nil?
          raise TypeError, "systemPromptは文字列である必要があります" unless systemPrompt.is_a?(String)
    end
    unless temperature.nil?
          raise TypeError, "temperatureは数値である必要があります" unless temperature.is_a?(Numeric)
    end
    super(includeContext: includeContext, maxTokens: maxTokens, messages: messages, metadata: metadata, modelPreferences: modelPreferences, stopSequences: stopSequences, systemPrompt: systemPrompt, temperature: temperature)
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

  # enumの値を検証するヘルパーメソッド
  def validate_enum(value, allowed_values, field_name)
    unless allowed_values.include?(value)
      formatted_values = allowed_values.map(&:to_s).join(", ")
      raise ArgumentError, "#{field_name}は次のいずれかである必要があります: #{formatted_values}"
    end
  end
end

# A request from the server to sample an LLM via the client. The client has full discretion over which model to select. The client should also inform the user before beginning sampling, to allow them to inspect the request (human in the loop) and decide whether to approve it.
# CreateMessageRequest クラスの型定義:
# - method: string
# - params: オブジェクト

CreateMessageRequest = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = CreateMessageRequestParam.new(**params)
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# CreateMessageResultMeta クラスの型定義:

CreateMessageResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# The client's response to a sampling/create_message request from the server. The client should inform the user before returning the sampled message, to allow them to inspect the response (human in the loop) and decide whether to allow the server to see it.
# CreateMessageResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - content: オブジェクト
# - model: string - The name of the model that generated the message.
# - role: any
# - stopReason: string - The reason why sampling stopped, if known.

CreateMessageResult = Data.define(:_meta, :content, :model, :role, :stopReason) do
  def initialize(_meta: nil, content:, model:, role:, stopReason: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = CreateMessageResultMeta.new(**_meta)
    end
    validate_any_of(content, [JSON.parse('{"$ref":"#/definitions/TextContent"}'), JSON.parse('{"$ref":"#/definitions/ImageContent"}')], "content")
    raise TypeError, "modelは文字列である必要があります" unless model.is_a?(String)

    unless stopReason.nil?
          raise TypeError, "stopReasonは文字列である必要があります" unless stopReason.is_a?(String)
    end
    super(_meta: _meta, content: content, model: model, role: role, stopReason: stopReason)
  end
  private

  # anyOfの値を検証するヘルパーメソッド
  def validate_any_of(value, schemas, field_name)
    # どれか1つのスキーマに一致すればOK
    return if schemas.any? { |schema| validate_schema(value, schema) }
    raise ArgumentError, "#{field_name}は許可されているスキーマのいずれにも一致しません"
  end

  # 値がスキーマに一致するかを検証するヘルパーメソッド
  def validate_schema(value, schema)
    # 基本的な型チェック
    if schema["type"]
      case schema["type"]
      when "string"
        return false unless value.is_a?(String)
      when "integer"
        return false unless value.is_a?(Integer)
      when "number"
        return false unless value.is_a?(Numeric)
      when "boolean"
        return false unless [true, false].include?(value)
      when "array"
        return false unless value.is_a?(Array)
      when "object"
        return false unless value.is_a?(Hash)
        # オブジェクトの場合は必須プロパティのチェック
        if schema["required"]
          schema["required"].each do |req_prop|
            return false unless value.key?(req_prop.to_sym) || value.key?(req_prop)
          end
        end
      end
    end

    # 他の制約も検証できるように拡張可能
    # ここではシンプルに型チェックのみ

    true # すべての検証をパス
  end
end

# JSONスキーマの型がobjectではありません

# EmbeddedResourceAnnotation クラスの型定義:
# - audience: any[] (配列) - Describes who the intended customer of this object or data is.

It can include multiple entries to indicate content useful for multiple audiences (e.g., `["user", "assistant"]`).
# - priority: number - Describes how important this data is for operating the server.

A value of 1 means "most important," and indicates that the data is
effectively required, while 0 means "least important," and indicates that
the data is entirely optional.

EmbeddedResourceAnnotation = Data.define(:audience, :priority) do
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

# The contents of a resource, embedded into a prompt or tool call result.

It is up to the client how best to render embedded resources for the benefit
of the LLM and/or the user.
# EmbeddedResource クラスの型定義:
# - annotations: オブジェクト
# - resource: オブジェクト
# - type: string

EmbeddedResource = Data.define(:annotations, :resource, :type) do
  def initialize(annotations: nil, resource:, type:)
    unless annotations.nil?
      raise TypeError, "annotationsはHashである必要があります" unless annotations.is_a?(Hash)
      annotations = EmbeddedResourceAnnotation.new(**annotations)
    end
    validate_any_of(resource, [JSON.parse('{"$ref":"#/definitions/TextResourceContents"}'), JSON.parse('{"$ref":"#/definitions/BlobResourceContents"}')], "resource")
    raise TypeError, "typeは文字列である必要があります" unless type.is_a?(String)
    super(annotations: annotations, resource: resource, type: type)
  end
  private

  # anyOfの値を検証するヘルパーメソッド
  def validate_any_of(value, schemas, field_name)
    # どれか1つのスキーマに一致すればOK
    return if schemas.any? { |schema| validate_schema(value, schema) }
    raise ArgumentError, "#{field_name}は許可されているスキーマのいずれにも一致しません"
  end

  # 値がスキーマに一致するかを検証するヘルパーメソッド
  def validate_schema(value, schema)
    # 基本的な型チェック
    if schema["type"]
      case schema["type"]
      when "string"
        return false unless value.is_a?(String)
      when "integer"
        return false unless value.is_a?(Integer)
      when "number"
        return false unless value.is_a?(Numeric)
      when "boolean"
        return false unless [true, false].include?(value)
      when "array"
        return false unless value.is_a?(Array)
      when "object"
        return false unless value.is_a?(Hash)
        # オブジェクトの場合は必須プロパティのチェック
        if schema["required"]
          schema["required"].each do |req_prop|
            return false unless value.key?(req_prop.to_sym) || value.key?(req_prop)
          end
        end
      end
    end

    # 他の制約も検証できるように拡張可能
    # ここではシンプルに型チェックのみ

    true # すべての検証をパス
  end
end

# JSONスキーマの型がobjectではありません

# Arguments to use for templating the prompt.
# GetPromptRequestParamArgument クラスの型定義:

GetPromptRequestParamArgument = Data.define(:) do
  def initialize()
    super()
  end
end

# GetPromptRequestParam クラスの型定義:
# - arguments: オブジェクト - Arguments to use for templating the prompt.
# - name: string - The name of the prompt or prompt template.

GetPromptRequestParam = Data.define(:arguments, :name) do
  def initialize(arguments: nil, name:)
    unless arguments.nil?
      raise TypeError, "argumentsはHashである必要があります" unless arguments.is_a?(Hash)
      arguments = GetPromptRequestParamArgument.new(**arguments)
    end
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    super(arguments: arguments, name: name)
  end
end

# Used by the client to get a prompt provided by the server.
# GetPromptRequest クラスの型定義:
# - method: string
# - params: オブジェクト

GetPromptRequest = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = GetPromptRequestParam.new(**params)
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# GetPromptResultMeta クラスの型定義:

GetPromptResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# The server's response to a prompts/get request from the client.
# GetPromptResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - description: string - An optional description for the prompt.
# - messages: any[] (配列)

GetPromptResult = Data.define(:_meta, :description, :messages) do
  def initialize(_meta: nil, description: nil, messages:)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = GetPromptResultMeta.new(**_meta)
    end
    unless description.nil?
          raise TypeError, "descriptionは文字列である必要があります" unless description.is_a?(String)
    end
    raise TypeError, "messagesは配列である必要があります" unless messages.is_a?(Array)
    validate_array_items(messages, "", "messages")
    super(_meta: _meta, description: description, messages: messages)
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

# ImageContentAnnotation クラスの型定義:
# - audience: any[] (配列) - Describes who the intended customer of this object or data is.

It can include multiple entries to indicate content useful for multiple audiences (e.g., `["user", "assistant"]`).
# - priority: number - Describes how important this data is for operating the server.

A value of 1 means "most important," and indicates that the data is
effectively required, while 0 means "least important," and indicates that
the data is entirely optional.

ImageContentAnnotation = Data.define(:audience, :priority) do
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

# An image provided to or from an LLM.
# ImageContent クラスの型定義:
# - annotations: オブジェクト
# - data: string (byte) - The base64-encoded image data.
# - mimeType: string - The MIME type of the image. Different providers may support different image types.
# - type: string

ImageContent = Data.define(:annotations, :data, :mimeType, :type) do
  def initialize(annotations: nil, data:, mimeType:, type:)
    unless annotations.nil?
      raise TypeError, "annotationsはHashである必要があります" unless annotations.is_a?(Hash)
      annotations = ImageContentAnnotation.new(**annotations)
    end
    raise TypeError, "dataは文字列である必要があります" unless data.is_a?(String)
    validate_format(data, "byte", "data")
    raise TypeError, "mimeTypeは文字列である必要があります" unless mimeType.is_a?(String)
    raise TypeError, "typeは文字列である必要があります" unless type.is_a?(String)
    super(annotations: annotations, data: data, mimeType: mimeType, type: type)
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

# Describes the name and version of an MCP implementation.
# Implementation クラスの型定義:
# - name: string
# - version: string

Implementation = Data.define(:name, :version) do
  def initialize(name:, version:)
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    raise TypeError, "versionは文字列である必要があります" unless version.is_a?(String)
    super(name: name, version: version)
  end
end

# InitializeRequestParam クラスの型定義:
# - capabilities: any
# - clientInfo: any
# - protocolVersion: string - The latest version of the Model Context Protocol that the client supports. The client MAY decide to support older versions as well.

InitializeRequestParam = Data.define(:capabilities, :clientInfo, :protocolVersion) do
  def initialize(capabilities:, clientInfo:, protocolVersion:)


    raise TypeError, "protocolVersionは文字列である必要があります" unless protocolVersion.is_a?(String)
    super(capabilities: capabilities, clientInfo: clientInfo, protocolVersion: protocolVersion)
  end
end

# This request is sent from the client to the server when it first connects, asking it to begin initialization.
# InitializeRequest クラスの型定義:
# - method: string
# - params: オブジェクト

InitializeRequest = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = InitializeRequestParam.new(**params)
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# InitializeResultMeta クラスの型定義:

InitializeResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# After receiving an initialize request from the client, the server sends this response.
# InitializeResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - capabilities: any
# - instructions: string - Instructions describing how to use the server and its features.

This can be used by clients to improve the LLM's understanding of available tools, resources, etc. It can be thought of like a "hint" to the model. For example, this information MAY be added to the system prompt.
# - protocolVersion: string - The version of the Model Context Protocol that the server wants to use. This may not match the version that the client requested. If the client cannot support this version, it MUST disconnect.
# - serverInfo: any

InitializeResult = Data.define(:_meta, :capabilities, :instructions, :protocolVersion, :serverInfo) do
  def initialize(_meta: nil, capabilities:, instructions: nil, protocolVersion:, serverInfo:)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = InitializeResultMeta.new(**_meta)
    end

    unless instructions.nil?
          raise TypeError, "instructionsは文字列である必要があります" unless instructions.is_a?(String)
    end
    raise TypeError, "protocolVersionは文字列である必要があります" unless protocolVersion.is_a?(String)

    super(_meta: _meta, capabilities: capabilities, instructions: instructions, protocolVersion: protocolVersion, serverInfo: serverInfo)
  end
end

# This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.
# InitializedNotificationParamMeta クラスの型定義:

InitializedNotificationParamMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# InitializedNotificationParam クラスの型定義:
# - _meta: オブジェクト - This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.

InitializedNotificationParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = InitializedNotificationParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# This notification is sent from the client to the server after initialization has finished.
# InitializedNotification クラスの型定義:
# - method: string
# - params: オブジェクト

InitializedNotification = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = InitializedNotificationParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# JSONRPCErrorError クラスの型定義:
# - code: integer - The error type that occurred.
# - data: any - Additional information about the error. The value of this member is defined by the sender (e.g. detailed error information, nested errors etc.).
# - message: string - A short description of the error. The message SHOULD be limited to a concise single sentence.

JSONRPCErrorError = Data.define(:code, :data, :message) do
  def initialize(code:, data: nil, message:)
    raise TypeError, "codeは整数である必要があります" unless code.is_a?(Integer)

    raise TypeError, "messageは文字列である必要があります" unless message.is_a?(String)
    super(code: code, data: data, message: message)
  end
end

# A response to a request that indicates an error occurred.
# JSONRPCError クラスの型定義:
# - error: オブジェクト
# - id: any
# - jsonrpc: string

JSONRPCError = Data.define(:error, :id, :jsonrpc) do
  def initialize(error:, id:, jsonrpc:)
    raise TypeError, "errorはHashである必要があります" unless error.is_a?(Hash)
    error = JSONRPCErrorError.new(**error)

    raise TypeError, "jsonrpcは文字列である必要があります" unless jsonrpc.is_a?(String)
    super(error: error, id: id, jsonrpc: jsonrpc)
  end
end

# JSONスキーマの型がobjectではありません

# This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.
# JSONRPCNotificationParamMeta クラスの型定義:

JSONRPCNotificationParamMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# JSONRPCNotificationParam クラスの型定義:
# - _meta: オブジェクト - This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.

JSONRPCNotificationParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = JSONRPCNotificationParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# A notification which does not expect a response.
# JSONRPCNotification クラスの型定義:
# - jsonrpc: string
# - method: string
# - params: オブジェクト

JSONRPCNotification = Data.define(:jsonrpc, :method, :params) do
  def initialize(jsonrpc:, method:, params: nil)
    raise TypeError, "jsonrpcは文字列である必要があります" unless jsonrpc.is_a?(String)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = JSONRPCNotificationParam.new(**params)
    end
    super(jsonrpc: jsonrpc, method: method, params: params)
  end
end

# JSONRPCRequestParamMeta クラスの型定義:
# - progressToken: any - If specified, the caller is requesting out-of-band progress notifications for this request (as represented by notifications/progress). The value of this parameter is an opaque token that will be attached to any subsequent notifications. The receiver is not obligated to provide these notifications.

JSONRPCRequestParamMeta = Data.define(:progressToken) do
  def initialize(progressToken: nil)

    super(progressToken: progressToken)
  end
end

# JSONRPCRequestParam クラスの型定義:
# - _meta: オブジェクト

JSONRPCRequestParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = JSONRPCRequestParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# A request that expects a response.
# JSONRPCRequest クラスの型定義:
# - id: any
# - jsonrpc: string
# - method: string
# - params: オブジェクト

JSONRPCRequest = Data.define(:id, :jsonrpc, :method, :params) do
  def initialize(id:, jsonrpc:, method:, params: nil)

    raise TypeError, "jsonrpcは文字列である必要があります" unless jsonrpc.is_a?(String)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = JSONRPCRequestParam.new(**params)
    end
    super(id: id, jsonrpc: jsonrpc, method: method, params: params)
  end
end

# A successful (non-error) response to a request.
# JSONRPCResponse クラスの型定義:
# - id: any
# - jsonrpc: string
# - result: any

JSONRPCResponse = Data.define(:id, :jsonrpc, :result) do
  def initialize(id:, jsonrpc:, result:)

    raise TypeError, "jsonrpcは文字列である必要があります" unless jsonrpc.is_a?(String)

    super(id: id, jsonrpc: jsonrpc, result: result)
  end
end

# ListPromptsRequestParam クラスの型定義:
# - cursor: string - An opaque token representing the current pagination position.
If provided, the server should return results starting after this cursor.

ListPromptsRequestParam = Data.define(:cursor) do
  def initialize(cursor: nil)
    unless cursor.nil?
          raise TypeError, "cursorは文字列である必要があります" unless cursor.is_a?(String)
    end
    super(cursor: cursor)
  end
end

# Sent from the client to request a list of prompts and prompt templates the server has.
# ListPromptsRequest クラスの型定義:
# - method: string
# - params: オブジェクト

ListPromptsRequest = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = ListPromptsRequestParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# ListPromptsResultMeta クラスの型定義:

ListPromptsResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# The server's response to a prompts/list request from the client.
# ListPromptsResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - nextCursor: string - An opaque token representing the pagination position after the last returned result.
If present, there may be more results available.
# - prompts: any[] (配列)

ListPromptsResult = Data.define(:_meta, :nextCursor, :prompts) do
  def initialize(_meta: nil, nextCursor: nil, prompts:)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = ListPromptsResultMeta.new(**_meta)
    end
    unless nextCursor.nil?
          raise TypeError, "nextCursorは文字列である必要があります" unless nextCursor.is_a?(String)
    end
    raise TypeError, "promptsは配列である必要があります" unless prompts.is_a?(Array)
    validate_array_items(prompts, "", "prompts")
    super(_meta: _meta, nextCursor: nextCursor, prompts: prompts)
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

# ListResourceTemplatesRequestParam クラスの型定義:
# - cursor: string - An opaque token representing the current pagination position.
If provided, the server should return results starting after this cursor.

ListResourceTemplatesRequestParam = Data.define(:cursor) do
  def initialize(cursor: nil)
    unless cursor.nil?
          raise TypeError, "cursorは文字列である必要があります" unless cursor.is_a?(String)
    end
    super(cursor: cursor)
  end
end

# Sent from the client to request a list of resource templates the server has.
# ListResourceTemplatesRequest クラスの型定義:
# - method: string
# - params: オブジェクト

ListResourceTemplatesRequest = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = ListResourceTemplatesRequestParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# ListResourceTemplatesResultMeta クラスの型定義:

ListResourceTemplatesResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# The server's response to a resources/templates/list request from the client.
# ListResourceTemplatesResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - nextCursor: string - An opaque token representing the pagination position after the last returned result.
If present, there may be more results available.
# - resourceTemplates: any[] (配列)

ListResourceTemplatesResult = Data.define(:_meta, :nextCursor, :resourceTemplates) do
  def initialize(_meta: nil, nextCursor: nil, resourceTemplates:)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = ListResourceTemplatesResultMeta.new(**_meta)
    end
    unless nextCursor.nil?
          raise TypeError, "nextCursorは文字列である必要があります" unless nextCursor.is_a?(String)
    end
    raise TypeError, "resourceTemplatesは配列である必要があります" unless resourceTemplates.is_a?(Array)
    validate_array_items(resourceTemplates, "", "resourceTemplates")
    super(_meta: _meta, nextCursor: nextCursor, resourceTemplates: resourceTemplates)
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

# ListResourcesRequestParam クラスの型定義:
# - cursor: string - An opaque token representing the current pagination position.
If provided, the server should return results starting after this cursor.

ListResourcesRequestParam = Data.define(:cursor) do
  def initialize(cursor: nil)
    unless cursor.nil?
          raise TypeError, "cursorは文字列である必要があります" unless cursor.is_a?(String)
    end
    super(cursor: cursor)
  end
end

# Sent from the client to request a list of resources the server has.
# ListResourcesRequest クラスの型定義:
# - method: string
# - params: オブジェクト

ListResourcesRequest = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = ListResourcesRequestParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# ListResourcesResultMeta クラスの型定義:

ListResourcesResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# The server's response to a resources/list request from the client.
# ListResourcesResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - nextCursor: string - An opaque token representing the pagination position after the last returned result.
If present, there may be more results available.
# - resources: any[] (配列)

ListResourcesResult = Data.define(:_meta, :nextCursor, :resources) do
  def initialize(_meta: nil, nextCursor: nil, resources:)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = ListResourcesResultMeta.new(**_meta)
    end
    unless nextCursor.nil?
          raise TypeError, "nextCursorは文字列である必要があります" unless nextCursor.is_a?(String)
    end
    raise TypeError, "resourcesは配列である必要があります" unless resources.is_a?(Array)
    validate_array_items(resources, "", "resources")
    super(_meta: _meta, nextCursor: nextCursor, resources: resources)
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

# ListRootsRequestParamMeta クラスの型定義:
# - progressToken: any - If specified, the caller is requesting out-of-band progress notifications for this request (as represented by notifications/progress). The value of this parameter is an opaque token that will be attached to any subsequent notifications. The receiver is not obligated to provide these notifications.

ListRootsRequestParamMeta = Data.define(:progressToken) do
  def initialize(progressToken: nil)

    super(progressToken: progressToken)
  end
end

# ListRootsRequestParam クラスの型定義:
# - _meta: オブジェクト

ListRootsRequestParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = ListRootsRequestParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# Sent from the server to request a list of root URIs from the client. Roots allow
servers to ask for specific directories or files to operate on. A common example
for roots is providing a set of repositories or directories a server should operate
on.

This request is typically used when the server needs to understand the file system
structure or access specific locations that the client has permission to read from.
# ListRootsRequest クラスの型定義:
# - method: string
# - params: オブジェクト

ListRootsRequest = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = ListRootsRequestParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# ListRootsResultMeta クラスの型定義:

ListRootsResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# The client's response to a roots/list request from the server.
This result contains an array of Root objects, each representing a root directory
or file that the server can operate on.
# ListRootsResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - roots: any[] (配列)

ListRootsResult = Data.define(:_meta, :roots) do
  def initialize(_meta: nil, roots:)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = ListRootsResultMeta.new(**_meta)
    end
    raise TypeError, "rootsは配列である必要があります" unless roots.is_a?(Array)
    validate_array_items(roots, "", "roots")
    super(_meta: _meta, roots: roots)
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

# ListToolsRequestParam クラスの型定義:
# - cursor: string - An opaque token representing the current pagination position.
If provided, the server should return results starting after this cursor.

ListToolsRequestParam = Data.define(:cursor) do
  def initialize(cursor: nil)
    unless cursor.nil?
          raise TypeError, "cursorは文字列である必要があります" unless cursor.is_a?(String)
    end
    super(cursor: cursor)
  end
end

# Sent from the client to request a list of tools the server has.
# ListToolsRequest クラスの型定義:
# - method: string
# - params: オブジェクト

ListToolsRequest = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = ListToolsRequestParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# ListToolsResultMeta クラスの型定義:

ListToolsResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# The server's response to a tools/list request from the client.
# ListToolsResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - nextCursor: string - An opaque token representing the pagination position after the last returned result.
If present, there may be more results available.
# - tools: any[] (配列)

ListToolsResult = Data.define(:_meta, :nextCursor, :tools) do
  def initialize(_meta: nil, nextCursor: nil, tools:)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = ListToolsResultMeta.new(**_meta)
    end
    unless nextCursor.nil?
          raise TypeError, "nextCursorは文字列である必要があります" unless nextCursor.is_a?(String)
    end
    raise TypeError, "toolsは配列である必要があります" unless tools.is_a?(Array)
    validate_array_items(tools, "", "tools")
    super(_meta: _meta, nextCursor: nextCursor, tools: tools)
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

# JSONスキーマの型がobjectではありません

# LoggingMessageNotificationParam クラスの型定義:
# - data: any - The data to be logged, such as a string message or an object. Any JSON serializable type is allowed here.
# - level: any - The severity of this log message.
# - logger: string - An optional name of the logger issuing this message.

LoggingMessageNotificationParam = Data.define(:data, :level, :logger) do
  def initialize(data:, level:, logger: nil)


    unless logger.nil?
          raise TypeError, "loggerは文字列である必要があります" unless logger.is_a?(String)
    end
    super(data: data, level: level, logger: logger)
  end
end

# Notification of a log message passed from server to client. If no logging/setLevel request has been sent from the client, the server MAY decide which messages to send automatically.
# LoggingMessageNotification クラスの型定義:
# - method: string
# - params: オブジェクト

LoggingMessageNotification = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = LoggingMessageNotificationParam.new(**params)
    super(method: method, params: params)
  end
end

# Hints to use for model selection.

Keys not declared here are currently left unspecified by the spec and are up
to the client to interpret.
# ModelHint クラスの型定義:
# - name: string - A hint for a model name.

The client SHOULD treat this as a substring of a model name; for example:
 - `claude-3-5-sonnet` should match `claude-3-5-sonnet-20241022`
 - `sonnet` should match `claude-3-5-sonnet-20241022`, `claude-3-sonnet-20240229`, etc.
 - `claude` should match any Claude model

The client MAY also map the string to a different provider's model name or a different model family, as long as it fills a similar niche; for example:
 - `gemini-1.5-flash` could match `claude-3-haiku-20240307`

ModelHint = Data.define(:name) do
  def initialize(name: nil)
    unless name.nil?
          raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    end
    super(name: name)
  end
end

# The server's preferences for model selection, requested of the client during sampling.

Because LLMs can vary along multiple dimensions, choosing the "best" model is
rarely straightforward.  Different models excel in different areas—some are
faster but less capable, others are more capable but more expensive, and so
on. This interface allows servers to express their priorities across multiple
dimensions to help clients make an appropriate selection for their use case.

These preferences are always advisory. The client MAY ignore them. It is also
up to the client to decide how to interpret these preferences and how to
balance them against other considerations.
# ModelPreferences クラスの型定義:
# - costPriority: number - How much to prioritize cost when selecting a model. A value of 0 means cost
is not important, while a value of 1 means cost is the most important
factor.
# - hints: any[] (配列) - Optional hints to use for model selection.

If multiple hints are specified, the client MUST evaluate them in order
(such that the first match is taken).

The client SHOULD prioritize these hints over the numeric priorities, but
MAY still use the priorities to select from ambiguous matches.
# - intelligencePriority: number - How much to prioritize intelligence and capabilities when selecting a
model. A value of 0 means intelligence is not important, while a value of 1
means intelligence is the most important factor.
# - speedPriority: number - How much to prioritize sampling speed (latency) when selecting a model. A
value of 0 means speed is not important, while a value of 1 means speed is
the most important factor.

ModelPreferences = Data.define(:costPriority, :hints, :intelligencePriority, :speedPriority) do
  def initialize(costPriority: nil, hints: nil, intelligencePriority: nil, speedPriority: nil)
    unless costPriority.nil?
          raise TypeError, "costPriorityは数値である必要があります" unless costPriority.is_a?(Numeric)
    end
    raise ArgumentError, "costPriorityは0以上である必要があります" if costPriority < 0
    raise ArgumentError, "costPriorityは1以下である必要があります" if costPriority > 1
    unless hints.nil?
          raise TypeError, "hintsは配列である必要があります" unless hints.is_a?(Array)
    end
    validate_array_items(hints, "", "hints") unless hints.nil?
    unless intelligencePriority.nil?
          raise TypeError, "intelligencePriorityは数値である必要があります" unless intelligencePriority.is_a?(Numeric)
    end
    raise ArgumentError, "intelligencePriorityは0以上である必要があります" if intelligencePriority < 0
    raise ArgumentError, "intelligencePriorityは1以下である必要があります" if intelligencePriority > 1
    unless speedPriority.nil?
          raise TypeError, "speedPriorityは数値である必要があります" unless speedPriority.is_a?(Numeric)
    end
    raise ArgumentError, "speedPriorityは0以上である必要があります" if speedPriority < 0
    raise ArgumentError, "speedPriorityは1以下である必要があります" if speedPriority > 1
    super(costPriority: costPriority, hints: hints, intelligencePriority: intelligencePriority, speedPriority: speedPriority)
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

# This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.
# NotificationParamMeta クラスの型定義:

NotificationParamMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# NotificationParam クラスの型定義:
# - _meta: オブジェクト - This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.

NotificationParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = NotificationParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# Notification クラスの型定義:
# - method: string
# - params: オブジェクト

Notification = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = NotificationParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# PaginatedRequestParam クラスの型定義:
# - cursor: string - An opaque token representing the current pagination position.
If provided, the server should return results starting after this cursor.

PaginatedRequestParam = Data.define(:cursor) do
  def initialize(cursor: nil)
    unless cursor.nil?
          raise TypeError, "cursorは文字列である必要があります" unless cursor.is_a?(String)
    end
    super(cursor: cursor)
  end
end

# PaginatedRequest クラスの型定義:
# - method: string
# - params: オブジェクト

PaginatedRequest = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = PaginatedRequestParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# PaginatedResultMeta クラスの型定義:

PaginatedResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# PaginatedResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - nextCursor: string - An opaque token representing the pagination position after the last returned result.
If present, there may be more results available.

PaginatedResult = Data.define(:_meta, :nextCursor) do
  def initialize(_meta: nil, nextCursor: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = PaginatedResultMeta.new(**_meta)
    end
    unless nextCursor.nil?
          raise TypeError, "nextCursorは文字列である必要があります" unless nextCursor.is_a?(String)
    end
    super(_meta: _meta, nextCursor: nextCursor)
  end
end

# PingRequestParamMeta クラスの型定義:
# - progressToken: any - If specified, the caller is requesting out-of-band progress notifications for this request (as represented by notifications/progress). The value of this parameter is an opaque token that will be attached to any subsequent notifications. The receiver is not obligated to provide these notifications.

PingRequestParamMeta = Data.define(:progressToken) do
  def initialize(progressToken: nil)

    super(progressToken: progressToken)
  end
end

# PingRequestParam クラスの型定義:
# - _meta: オブジェクト

PingRequestParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = PingRequestParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# A ping, issued by either the server or the client, to check that the other party is still alive. The receiver must promptly respond, or else may be disconnected.
# PingRequest クラスの型定義:
# - method: string
# - params: オブジェクト

PingRequest = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = PingRequestParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# ProgressNotificationParam クラスの型定義:
# - progress: number - The progress thus far. This should increase every time progress is made, even if the total is unknown.
# - progressToken: any - The progress token which was given in the initial request, used to associate this notification with the request that is proceeding.
# - total: number - Total number of items to process (or total progress required), if known.

ProgressNotificationParam = Data.define(:progress, :progressToken, :total) do
  def initialize(progress:, progressToken:, total: nil)
    raise TypeError, "progressは数値である必要があります" unless progress.is_a?(Numeric)

    unless total.nil?
          raise TypeError, "totalは数値である必要があります" unless total.is_a?(Numeric)
    end
    super(progress: progress, progressToken: progressToken, total: total)
  end
end

# An out-of-band notification used to inform the receiver of a progress update for a long-running request.
# ProgressNotification クラスの型定義:
# - method: string
# - params: オブジェクト

ProgressNotification = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = ProgressNotificationParam.new(**params)
    super(method: method, params: params)
  end
end

# JSONスキーマの型がobjectではありません

# A prompt or prompt template that the server offers.
# Prompt クラスの型定義:
# - arguments: any[] (配列) - A list of arguments to use for templating the prompt.
# - description: string - An optional description of what this prompt provides
# - name: string - The name of the prompt or prompt template.

Prompt = Data.define(:arguments, :description, :name) do
  def initialize(arguments: nil, description: nil, name:)
    unless arguments.nil?
          raise TypeError, "argumentsは配列である必要があります" unless arguments.is_a?(Array)
    end
    validate_array_items(arguments, "", "arguments") unless arguments.nil?
    unless description.nil?
          raise TypeError, "descriptionは文字列である必要があります" unless description.is_a?(String)
    end
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    super(arguments: arguments, description: description, name: name)
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

# Describes an argument that a prompt can accept.
# PromptArgument クラスの型定義:
# - description: string - A human-readable description of the argument.
# - name: string - The name of the argument.
# - required: boolean - Whether this argument must be provided.

PromptArgument = Data.define(:description, :name, :required) do
  def initialize(description: nil, name:, required: nil)
    unless description.nil?
          raise TypeError, "descriptionは文字列である必要があります" unless description.is_a?(String)
    end
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    unless required.nil?
          raise TypeError, "requiredは真偽値である必要があります" unless [true, false].include?(required)
    end
    super(description: description, name: name, required: required)
  end
end

# This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.
# PromptListChangedNotificationParamMeta クラスの型定義:

PromptListChangedNotificationParamMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# PromptListChangedNotificationParam クラスの型定義:
# - _meta: オブジェクト - This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.

PromptListChangedNotificationParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = PromptListChangedNotificationParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# An optional notification from the server to the client, informing it that the list of prompts it offers has changed. This may be issued by servers without any previous subscription from the client.
# PromptListChangedNotification クラスの型定義:
# - method: string
# - params: オブジェクト

PromptListChangedNotification = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = PromptListChangedNotificationParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# Describes a message returned as part of a prompt.

This is similar to `SamplingMessage`, but also supports the embedding of
resources from the MCP server.
# PromptMessage クラスの型定義:
# - content: オブジェクト
# - role: any

PromptMessage = Data.define(:content, :role) do
  def initialize(content:, role:)
    validate_any_of(content, [JSON.parse('{"$ref":"#/definitions/TextContent"}'), JSON.parse('{"$ref":"#/definitions/ImageContent"}'), JSON.parse('{"$ref":"#/definitions/EmbeddedResource"}')], "content")

    super(content: content, role: role)
  end
  private

  # anyOfの値を検証するヘルパーメソッド
  def validate_any_of(value, schemas, field_name)
    # どれか1つのスキーマに一致すればOK
    return if schemas.any? { |schema| validate_schema(value, schema) }
    raise ArgumentError, "#{field_name}は許可されているスキーマのいずれにも一致しません"
  end

  # 値がスキーマに一致するかを検証するヘルパーメソッド
  def validate_schema(value, schema)
    # 基本的な型チェック
    if schema["type"]
      case schema["type"]
      when "string"
        return false unless value.is_a?(String)
      when "integer"
        return false unless value.is_a?(Integer)
      when "number"
        return false unless value.is_a?(Numeric)
      when "boolean"
        return false unless [true, false].include?(value)
      when "array"
        return false unless value.is_a?(Array)
      when "object"
        return false unless value.is_a?(Hash)
        # オブジェクトの場合は必須プロパティのチェック
        if schema["required"]
          schema["required"].each do |req_prop|
            return false unless value.key?(req_prop.to_sym) || value.key?(req_prop)
          end
        end
      end
    end

    # 他の制約も検証できるように拡張可能
    # ここではシンプルに型チェックのみ

    true # すべての検証をパス
  end
end

# Identifies a prompt.
# PromptReference クラスの型定義:
# - name: string - The name of the prompt or prompt template
# - type: string

PromptReference = Data.define(:name, :type) do
  def initialize(name:, type:)
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    raise TypeError, "typeは文字列である必要があります" unless type.is_a?(String)
    super(name: name, type: type)
  end
end

# ReadResourceRequestParam クラスの型定義:
# - uri: string (uri) - The URI of the resource to read. The URI can use any protocol; it is up to the server how to interpret it.

ReadResourceRequestParam = Data.define(:uri) do
  def initialize(uri:)
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri", "uri")
    super(uri: uri)
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

# Sent from the client to the server, to read a specific resource URI.
# ReadResourceRequest クラスの型定義:
# - method: string
# - params: オブジェクト

ReadResourceRequest = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = ReadResourceRequestParam.new(**params)
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# ReadResourceResultMeta クラスの型定義:

ReadResourceResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# The server's response to a resources/read request from the client.
# ReadResourceResult クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# - contents: any[] (配列)

ReadResourceResult = Data.define(:_meta, :contents) do
  def initialize(_meta: nil, contents:)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = ReadResourceResultMeta.new(**_meta)
    end
    raise TypeError, "contentsは配列である必要があります" unless contents.is_a?(Array)
    validate_array_items(contents, "", "contents")
    super(_meta: _meta, contents: contents)
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

# RequestParamMeta クラスの型定義:
# - progressToken: any - If specified, the caller is requesting out-of-band progress notifications for this request (as represented by notifications/progress). The value of this parameter is an opaque token that will be attached to any subsequent notifications. The receiver is not obligated to provide these notifications.

RequestParamMeta = Data.define(:progressToken) do
  def initialize(progressToken: nil)

    super(progressToken: progressToken)
  end
end

# RequestParam クラスの型定義:
# - _meta: オブジェクト

RequestParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = RequestParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# Request クラスの型定義:
# - method: string
# - params: オブジェクト

Request = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = RequestParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# JSONスキーマの型がobjectではありません

# ResourceAnnotation クラスの型定義:
# - audience: any[] (配列) - Describes who the intended customer of this object or data is.

It can include multiple entries to indicate content useful for multiple audiences (e.g., `["user", "assistant"]`).
# - priority: number - Describes how important this data is for operating the server.

A value of 1 means "most important," and indicates that the data is
effectively required, while 0 means "least important," and indicates that
the data is entirely optional.

ResourceAnnotation = Data.define(:audience, :priority) do
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

# A known resource that the server is capable of reading.
# Resource クラスの型定義:
# - annotations: オブジェクト
# - description: string - A description of what this resource represents.

This can be used by clients to improve the LLM's understanding of available resources. It can be thought of like a "hint" to the model.
# - mimeType: string - The MIME type of this resource, if known.
# - name: string - A human-readable name for this resource.

This can be used by clients to populate UI elements.
# - size: integer - The size of the raw resource content, in bytes (i.e., before base64 encoding or any tokenization), if known.

This can be used by Hosts to display file sizes and estimate context window usage.
# - uri: string (uri) - The URI of this resource.

Resource = Data.define(:annotations, :description, :mimeType, :name, :size, :uri) do
  def initialize(annotations: nil, description: nil, mimeType: nil, name:, size: nil, uri:)
    unless annotations.nil?
      raise TypeError, "annotationsはHashである必要があります" unless annotations.is_a?(Hash)
      annotations = ResourceAnnotation.new(**annotations)
    end
    unless description.nil?
          raise TypeError, "descriptionは文字列である必要があります" unless description.is_a?(String)
    end
    unless mimeType.nil?
          raise TypeError, "mimeTypeは文字列である必要があります" unless mimeType.is_a?(String)
    end
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    unless size.nil?
          raise TypeError, "sizeは整数である必要があります" unless size.is_a?(Integer)
    end
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri", "uri")
    super(annotations: annotations, description: description, mimeType: mimeType, name: name, size: size, uri: uri)
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

# The contents of a specific resource or sub-resource.
# ResourceContents クラスの型定義:
# - mimeType: string - The MIME type of this resource, if known.
# - uri: string (uri) - The URI of this resource.

ResourceContents = Data.define(:mimeType, :uri) do
  def initialize(mimeType: nil, uri:)
    unless mimeType.nil?
          raise TypeError, "mimeTypeは文字列である必要があります" unless mimeType.is_a?(String)
    end
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri", "uri")
    super(mimeType: mimeType, uri: uri)
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

# This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.
# ResourceListChangedNotificationParamMeta クラスの型定義:

ResourceListChangedNotificationParamMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# ResourceListChangedNotificationParam クラスの型定義:
# - _meta: オブジェクト - This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.

ResourceListChangedNotificationParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = ResourceListChangedNotificationParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# An optional notification from the server to the client, informing it that the list of resources it can read from has changed. This may be issued by servers without any previous subscription from the client.
# ResourceListChangedNotification クラスの型定義:
# - method: string
# - params: オブジェクト

ResourceListChangedNotification = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = ResourceListChangedNotificationParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# A reference to a resource or resource template definition.
# ResourceReference クラスの型定義:
# - type: string
# - uri: string (uri-template) - The URI or URI template of the resource.

ResourceReference = Data.define(:type, :uri) do
  def initialize(type:, uri:)
    raise TypeError, "typeは文字列である必要があります" unless type.is_a?(String)
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri-template", "uri")
    super(type: type, uri: uri)
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

# ResourceTemplateAnnotation クラスの型定義:
# - audience: any[] (配列) - Describes who the intended customer of this object or data is.

It can include multiple entries to indicate content useful for multiple audiences (e.g., `["user", "assistant"]`).
# - priority: number - Describes how important this data is for operating the server.

A value of 1 means "most important," and indicates that the data is
effectively required, while 0 means "least important," and indicates that
the data is entirely optional.

ResourceTemplateAnnotation = Data.define(:audience, :priority) do
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

# A template description for resources available on the server.
# ResourceTemplate クラスの型定義:
# - annotations: オブジェクト
# - description: string - A description of what this template is for.

This can be used by clients to improve the LLM's understanding of available resources. It can be thought of like a "hint" to the model.
# - mimeType: string - The MIME type for all resources that match this template. This should only be included if all resources matching this template have the same type.
# - name: string - A human-readable name for the type of resource this template refers to.

This can be used by clients to populate UI elements.
# - uriTemplate: string (uri-template) - A URI template (according to RFC 6570) that can be used to construct resource URIs.

ResourceTemplate = Data.define(:annotations, :description, :mimeType, :name, :uriTemplate) do
  def initialize(annotations: nil, description: nil, mimeType: nil, name:, uriTemplate:)
    unless annotations.nil?
      raise TypeError, "annotationsはHashである必要があります" unless annotations.is_a?(Hash)
      annotations = ResourceTemplateAnnotation.new(**annotations)
    end
    unless description.nil?
          raise TypeError, "descriptionは文字列である必要があります" unless description.is_a?(String)
    end
    unless mimeType.nil?
          raise TypeError, "mimeTypeは文字列である必要があります" unless mimeType.is_a?(String)
    end
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    raise TypeError, "uriTemplateは文字列である必要があります" unless uriTemplate.is_a?(String)
    validate_format(uriTemplate, "uri-template", "uriTemplate")
    super(annotations: annotations, description: description, mimeType: mimeType, name: name, uriTemplate: uriTemplate)
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

# ResourceUpdatedNotificationParam クラスの型定義:
# - uri: string (uri) - The URI of the resource that has been updated. This might be a sub-resource of the one that the client actually subscribed to.

ResourceUpdatedNotificationParam = Data.define(:uri) do
  def initialize(uri:)
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri", "uri")
    super(uri: uri)
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

# A notification from the server to the client, informing it that a resource has changed and may need to be read again. This should only be sent if the client previously sent a resources/subscribe request.
# ResourceUpdatedNotification クラスの型定義:
# - method: string
# - params: オブジェクト

ResourceUpdatedNotification = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = ResourceUpdatedNotificationParam.new(**params)
    super(method: method, params: params)
  end
end

# This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
# ResultMeta クラスの型定義:

ResultMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# Result クラスの型定義:
# - _meta: オブジェクト - This result property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.

Result = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = ResultMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# JSONスキーマの型がobjectではありません

# Represents a root directory or file that the server can operate on.
# Root クラスの型定義:
# - name: string - An optional name for the root. This can be used to provide a human-readable
identifier for the root, which may be useful for display purposes or for
referencing the root in other parts of the application.
# - uri: string (uri) - The URI identifying the root. This *must* start with file:// for now.
This restriction may be relaxed in future versions of the protocol to allow
other URI schemes.

Root = Data.define(:name, :uri) do
  def initialize(name: nil, uri:)
    unless name.nil?
          raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    end
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri", "uri")
    super(name: name, uri: uri)
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

# This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.
# RootsListChangedNotificationParamMeta クラスの型定義:

RootsListChangedNotificationParamMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# RootsListChangedNotificationParam クラスの型定義:
# - _meta: オブジェクト - This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.

RootsListChangedNotificationParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = RootsListChangedNotificationParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# A notification from the client to the server, informing it that the list of roots has changed.
This notification should be sent whenever the client adds, removes, or modifies any root.
The server should then request an updated list of roots using the ListRootsRequest.
# RootsListChangedNotification クラスの型定義:
# - method: string
# - params: オブジェクト

RootsListChangedNotification = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = RootsListChangedNotificationParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# Describes a message issued to or received from an LLM API.
# SamplingMessage クラスの型定義:
# - content: オブジェクト
# - role: any

SamplingMessage = Data.define(:content, :role) do
  def initialize(content:, role:)
    validate_any_of(content, [JSON.parse('{"$ref":"#/definitions/TextContent"}'), JSON.parse('{"$ref":"#/definitions/ImageContent"}')], "content")

    super(content: content, role: role)
  end
  private

  # anyOfの値を検証するヘルパーメソッド
  def validate_any_of(value, schemas, field_name)
    # どれか1つのスキーマに一致すればOK
    return if schemas.any? { |schema| validate_schema(value, schema) }
    raise ArgumentError, "#{field_name}は許可されているスキーマのいずれにも一致しません"
  end

  # 値がスキーマに一致するかを検証するヘルパーメソッド
  def validate_schema(value, schema)
    # 基本的な型チェック
    if schema["type"]
      case schema["type"]
      when "string"
        return false unless value.is_a?(String)
      when "integer"
        return false unless value.is_a?(Integer)
      when "number"
        return false unless value.is_a?(Numeric)
      when "boolean"
        return false unless [true, false].include?(value)
      when "array"
        return false unless value.is_a?(Array)
      when "object"
        return false unless value.is_a?(Hash)
        # オブジェクトの場合は必須プロパティのチェック
        if schema["required"]
          schema["required"].each do |req_prop|
            return false unless value.key?(req_prop.to_sym) || value.key?(req_prop)
          end
        end
      end
    end

    # 他の制約も検証できるように拡張可能
    # ここではシンプルに型チェックのみ

    true # すべての検証をパス
  end
end

# Experimental, non-standard capabilities that the server supports.
# ServerCapabilitiesExperimental クラスの型定義:

ServerCapabilitiesExperimental = Data.define(:) do
  def initialize()
    super()
  end
end

# Present if the server supports sending log messages to the client.
# ServerCapabilitiesLogging クラスの型定義:

ServerCapabilitiesLogging = Data.define(:) do
  def initialize()
    super()
  end
end

# Present if the server offers any prompt templates.
# ServerCapabilitiesPrompt クラスの型定義:
# - listChanged: boolean - Whether this server supports notifications for changes to the prompt list.

ServerCapabilitiesPrompt = Data.define(:listChanged) do
  def initialize(listChanged: nil)
    unless listChanged.nil?
          raise TypeError, "listChangedは真偽値である必要があります" unless [true, false].include?(listChanged)
    end
    super(listChanged: listChanged)
  end
end

# Present if the server offers any resources to read.
# ServerCapabilitiesResource クラスの型定義:
# - listChanged: boolean - Whether this server supports notifications for changes to the resource list.
# - subscribe: boolean - Whether this server supports subscribing to resource updates.

ServerCapabilitiesResource = Data.define(:listChanged, :subscribe) do
  def initialize(listChanged: nil, subscribe: nil)
    unless listChanged.nil?
          raise TypeError, "listChangedは真偽値である必要があります" unless [true, false].include?(listChanged)
    end
    unless subscribe.nil?
          raise TypeError, "subscribeは真偽値である必要があります" unless [true, false].include?(subscribe)
    end
    super(listChanged: listChanged, subscribe: subscribe)
  end
end

# Present if the server offers any tools to call.
# ServerCapabilitiesTool クラスの型定義:
# - listChanged: boolean - Whether this server supports notifications for changes to the tool list.

ServerCapabilitiesTool = Data.define(:listChanged) do
  def initialize(listChanged: nil)
    unless listChanged.nil?
          raise TypeError, "listChangedは真偽値である必要があります" unless [true, false].include?(listChanged)
    end
    super(listChanged: listChanged)
  end
end

# Capabilities that a server may support. Known capabilities are defined here, in this schema, but this is not a closed set: any server can define its own, additional capabilities.
# ServerCapabilities クラスの型定義:
# - experimental: オブジェクト - Experimental, non-standard capabilities that the server supports.
# - logging: オブジェクト - Present if the server supports sending log messages to the client.
# - prompts: オブジェクト - Present if the server offers any prompt templates.
# - resources: オブジェクト - Present if the server offers any resources to read.
# - tools: オブジェクト - Present if the server offers any tools to call.

ServerCapabilities = Data.define(:experimental, :logging, :prompts, :resources, :tools) do
  def initialize(experimental: nil, logging: nil, prompts: nil, resources: nil, tools: nil)
    unless experimental.nil?
      raise TypeError, "experimentalはHashである必要があります" unless experimental.is_a?(Hash)
      experimental = ServerCapabilitiesExperimental.new(**experimental)
    end
    unless logging.nil?
      raise TypeError, "loggingはHashである必要があります" unless logging.is_a?(Hash)
      logging = ServerCapabilitiesLogging.new(**logging)
    end
    unless prompts.nil?
      raise TypeError, "promptsはHashである必要があります" unless prompts.is_a?(Hash)
      prompts = ServerCapabilitiesPrompt.new(**prompts)
    end
    unless resources.nil?
      raise TypeError, "resourcesはHashである必要があります" unless resources.is_a?(Hash)
      resources = ServerCapabilitiesResource.new(**resources)
    end
    unless tools.nil?
      raise TypeError, "toolsはHashである必要があります" unless tools.is_a?(Hash)
      tools = ServerCapabilitiesTool.new(**tools)
    end
    super(experimental: experimental, logging: logging, prompts: prompts, resources: resources, tools: tools)
  end
end

# JSONスキーマの型がobjectではありません

# JSONスキーマの型がobjectではありません

# JSONスキーマの型がobjectではありません

# SetLevelRequestParam クラスの型定義:
# - level: any - The level of logging that the client wants to receive from the server. The server should send all logs at this level and higher (i.e., more severe) to the client as notifications/message.

SetLevelRequestParam = Data.define(:level) do
  def initialize(level:)

    super(level: level)
  end
end

# A request from the client to the server, to enable or adjust logging.
# SetLevelRequest クラスの型定義:
# - method: string
# - params: オブジェクト

SetLevelRequest = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = SetLevelRequestParam.new(**params)
    super(method: method, params: params)
  end
end

# SubscribeRequestParam クラスの型定義:
# - uri: string (uri) - The URI of the resource to subscribe to. The URI can use any protocol; it is up to the server how to interpret it.

SubscribeRequestParam = Data.define(:uri) do
  def initialize(uri:)
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri", "uri")
    super(uri: uri)
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

# Sent from the client to request resources/updated notifications from the server whenever a particular resource changes.
# SubscribeRequest クラスの型定義:
# - method: string
# - params: オブジェクト

SubscribeRequest = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = SubscribeRequestParam.new(**params)
    super(method: method, params: params)
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

# TextResourceContents クラスの型定義:
# - mimeType: string - The MIME type of this resource, if known.
# - text: string - The text of the item. This must only be set if the item can actually be represented as text (not binary data).
# - uri: string (uri) - The URI of this resource.

TextResourceContents = Data.define(:mimeType, :text, :uri) do
  def initialize(mimeType: nil, text:, uri:)
    unless mimeType.nil?
          raise TypeError, "mimeTypeは文字列である必要があります" unless mimeType.is_a?(String)
    end
    raise TypeError, "textは文字列である必要があります" unless text.is_a?(String)
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri", "uri")
    super(mimeType: mimeType, text: text, uri: uri)
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

# ToolInputschemaPropertie クラスの型定義:

ToolInputschemaPropertie = Data.define(:) do
  def initialize()
    super()
  end
end

# A JSON Schema object defining the expected parameters for the tool.
# ToolInputschema クラスの型定義:
# - properties: オブジェクト
# - required: string[] (配列)
# - type: string

ToolInputschema = Data.define(:properties, :required, :type) do
  def initialize(properties: nil, required: nil, type:)
    unless properties.nil?
      raise TypeError, "propertiesはHashである必要があります" unless properties.is_a?(Hash)
      properties = ToolInputschemaPropertie.new(**properties)
    end
    unless required.nil?
          raise TypeError, "requiredは配列である必要があります" unless required.is_a?(Array)
    end
    validate_array_items(required, "string", "required") unless required.nil?
    raise TypeError, "typeは文字列である必要があります" unless type.is_a?(String)
    super(properties: properties, required: required, type: type)
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

# Definition for a tool the client can call.
# Tool クラスの型定義:
# - description: string - A human-readable description of the tool.
# - inputSchema: オブジェクト - A JSON Schema object defining the expected parameters for the tool.
# - name: string - The name of the tool.

Tool = Data.define(:description, :inputSchema, :name) do
  def initialize(description: nil, inputSchema:, name:)
    unless description.nil?
          raise TypeError, "descriptionは文字列である必要があります" unless description.is_a?(String)
    end
    raise TypeError, "inputSchemaはHashである必要があります" unless inputSchema.is_a?(Hash)
    inputSchema = ToolInputschema.new(**inputSchema)
    raise TypeError, "nameは文字列である必要があります" unless name.is_a?(String)
    super(description: description, inputSchema: inputSchema, name: name)
  end
end

# This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.
# ToolListChangedNotificationParamMeta クラスの型定義:

ToolListChangedNotificationParamMeta = Data.define(:) do
  def initialize()
    super()
  end
end

# ToolListChangedNotificationParam クラスの型定義:
# - _meta: オブジェクト - This parameter name is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.

ToolListChangedNotificationParam = Data.define(:_meta) do
  def initialize(_meta: nil)
    unless _meta.nil?
      raise TypeError, "_metaはHashである必要があります" unless _meta.is_a?(Hash)
      _meta = ToolListChangedNotificationParamMeta.new(**_meta)
    end
    super(_meta: _meta)
  end
end

# An optional notification from the server to the client, informing it that the list of tools it offers has changed. This may be issued by servers without any previous subscription from the client.
# ToolListChangedNotification クラスの型定義:
# - method: string
# - params: オブジェクト

ToolListChangedNotification = Data.define(:method, :params) do
  def initialize(method:, params: nil)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    unless params.nil?
      raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
      params = ToolListChangedNotificationParam.new(**params)
    end
    super(method: method, params: params)
  end
end

# UnsubscribeRequestParam クラスの型定義:
# - uri: string (uri) - The URI of the resource to unsubscribe from.

UnsubscribeRequestParam = Data.define(:uri) do
  def initialize(uri:)
    raise TypeError, "uriは文字列である必要があります" unless uri.is_a?(String)
    validate_format(uri, "uri", "uri")
    super(uri: uri)
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

# Sent from the client to request cancellation of resources/updated notifications from the server. This should follow a previous resources/subscribe request.
# UnsubscribeRequest クラスの型定義:
# - method: string
# - params: オブジェクト

UnsubscribeRequest = Data.define(:method, :params) do
  def initialize(method:, params:)
    raise TypeError, "methodは文字列である必要があります" unless method.is_a?(String)
    raise TypeError, "paramsはHashである必要があります" unless params.is_a?(Hash)
    params = UnsubscribeRequestParam.new(**params)
    super(method: method, params: params)
  end
end