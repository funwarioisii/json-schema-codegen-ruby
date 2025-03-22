# frozen_string_literal: true

require "optparse"
require "json_schema_codegen"

module JsonSchemaCodegen
  # コマンドラインインターフェースを提供するクラス
  class CLI
    def initialize(args = ARGV)
      @args = args
      @options = {
        output: nil,
        class_name: nil,
        definition: nil,
        list_definitions: false,
        all_definitions: false,
        multi_definitions: nil
      }
    end

    # コマンドライン引数を解析して処理を実行する
    def run
      parse_options
      process_command
    end

    private

    # コマンドライン引数を解析する
    def parse_options
      parser = OptionParser.new do |opts|
        opts.banner = "使用法: json_schema_codegen [オプション] <schema_file>"

        opts.on("-o", "--output FILE", "出力ファイルパス") do |file|
          @options[:output] = file
        end

        opts.on("-c", "--class-name NAME", "生成するクラス名") do |name|
          @options[:class_name] = name
        end

        opts.on("-d", "--definition NAME", "生成する定義名") do |name|
          @options[:definition] = name
        end

        opts.on("-m", "--multi-definitions NAMES", "生成する複数の定義名（カンマ区切り）") do |names|
          @options[:multi_definitions] = names.split(",")
        end

        opts.on("-a", "--all-definitions", "すべての定義からクラスを生成") do
          @options[:all_definitions] = true
        end

        opts.on("-l", "--list-definitions", "定義名の一覧を表示") do
          @options[:list_definitions] = true
        end

        opts.on("-h", "--help", "ヘルプを表示") do
          puts opts
          exit
        end
      end

      parser.parse!(@args)

      # スキーマファイルが指定されているか確認
      if @args.empty?
        puts "JSONスキーマファイルを指定してください。"
        puts parser
        exit 1
      end

      @schema_file = @args[0]

      # ファイルの存在を確認
      unless File.exist?(@schema_file)
        puts "指定されたファイルが見つかりません: #{@schema_file}"
        exit 1
      end
    end

    # コマンドを処理する
    def process_command
      # 定義の一覧表示
      if @options[:list_definitions]
        definitions = JsonSchemaCodegen.list_definitions_from_file(@schema_file)
        if definitions.empty?
          puts "このスキーマには定義が含まれていません。"
        else
          puts "利用可能な定義一覧:"
          definitions.each do |name|
            puts "- #{name}"
          end
        end
        return
      end

      # Rubyコード生成
      ruby_code = generate_ruby_code

      # 結果の出力
      if @options[:output]
        File.write(@options[:output], ruby_code)
        puts "Rubyコードを生成しました: #{@options[:output]}"
      else
        puts ruby_code
      end
    end

    # Rubyコードを生成する
    def generate_ruby_code
      if @options[:definition]
        # 指定した定義からクラスを生成
        JsonSchemaCodegen.generate_from_file_definition(
          @schema_file,
          @options[:definition],
          @options[:class_name]
        )
      elsif @options[:multi_definitions]
        # 複数の定義からクラスを生成
        JsonSchemaCodegen.generate_from_file_multiple_definitions(
          @schema_file,
          @options[:multi_definitions]
        )
      elsif @options[:all_definitions]
        # すべての定義からクラスを生成
        definitions = JsonSchemaCodegen.list_definitions_from_file(@schema_file)
        JsonSchemaCodegen.generate_from_file_multiple_definitions(
          @schema_file,
          definitions
        )
      else
        # 従来の方法（ルートオブジェクトからクラスを生成）
        # クラス名が指定されていない場合はファイル名から生成
        @options[:class_name] ||= File.basename(@schema_file, ".*").split("_").map(&:capitalize).join
        JsonSchemaCodegen.generate_from_file(@schema_file, @options[:class_name])
      end
    end
  end
end
