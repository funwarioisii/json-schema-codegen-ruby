#!/bin/bash

# schema.jsonから定義を抽出してRubyコードを生成するヘルパースクリプト
# 使用方法: ./tools/extract_and_generate.sh <定義名> [出力ファイル]

# スクリプトの場所を取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# プロジェクトのルートディレクトリを設定
ROOT_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
# schemaファイルのパス
SCHEMA_PATH="$ROOT_DIR/spec/fixtures/schema.json"

if [ -z "$1" ]; then
  echo "使用方法: $0 <定義名> [出力ファイル]"
  echo "例: $0 BlobResourceContents blob.rb"
  echo ""
  echo "利用可能な定義一覧:"
  jq -r '.definitions | keys[]' "$SCHEMA_PATH" | sort
  exit 1
fi

DEFINITION_NAME="$1"
OUTPUT_FILE="$2"

# 定義の存在確認
if ! jq -e ".definitions.$DEFINITION_NAME" "$SCHEMA_PATH" > /dev/null 2>&1; then
  echo "エラー: 定義 '$DEFINITION_NAME' は $SCHEMA_PATH に存在しません"
  echo "利用可能な定義一覧:"
  jq -r '.definitions | keys[]' "$SCHEMA_PATH" | sort
  exit 1
fi

# 定義を抽出して一時ファイルに保存
TEMP_FILE=$(mktemp)
jq ".definitions.$DEFINITION_NAME" "$SCHEMA_PATH" > "$TEMP_FILE"

# コード生成
if [ -z "$OUTPUT_FILE" ]; then
  # 標準出力に出力
  "$ROOT_DIR/bin/json_schema_codegen" -c "$DEFINITION_NAME" "$TEMP_FILE"
else
  # ファイルに出力
  "$ROOT_DIR/bin/json_schema_codegen" -c "$DEFINITION_NAME" -o "$OUTPUT_FILE" "$TEMP_FILE"
  echo "コードを $OUTPUT_FILE に生成しました"
fi

# 一時ファイルを削除
rm "$TEMP_FILE" 