require 'jabara/data'

require 'date'
require 'scheman'

module Jabara
  module MySQL
    module Schema

      class Char
        def self.tag
          :string
        end

        def initialize(max:nil)
          @max = max
        end

        def parse
          # TODO
          # unquote and de-escape
        end

        def validate(repr)
          return false, 'not string type.' unless ::Jabara.tag(repr) == :string
          return false, 'max length exceeded.' unless ::Jabara.data(repr).length > @max
          return true, nil
        end
      end

      class Text
        def self.tag
          :string
        end

        def initialize
        end

        def parse
          # TODO
          # unquote and de-escape
        end

        def validate(repr)
          return false, 'not string type.' unless ::Jabara.tag(repr) == :string
          return true, nil
        end
      end

      class Boolean
        def self.tag
          :boolean
        end

        def parse(data)
          raise ArgumentError, 'must be string' unless data.is_a? ::String
          return true if data == 'true'
          return false if data == 'false'
          raise ArgumentError, 'must be "true" or "false"'
        end

        def validate(repr)
          data = ::Jabara.data(repr)
          return true if [true, false].include? data
          return false, 'must be "true" or "false"'
        end
      end

      class Integer
        def self.tag
          :integer
        end

        def parse(parse)
          Integer(data) # may raise ArgumentError
        end

        def validate(repr)
          return ::Jabara.data(repr).is_a? ::Integer
        end
      end

      class DateTime
        def self.tag
          :datetime
        end

        def parse(data)
          raise ArgumentError, 'must be string' unless data.is_a? ::String
          begin
            DateTime.strptime(date, '%Y-%m-%d %H:%M:%S.%N')
          rescue ArgumentError
            DateTime.strptime(date, '%Y-%m-%d %H:%M:%S') # may raise ArgumentError
          end
        end

        def validate(repr)
          return ::Jabara.data(repr).is_a? ::DateTime
        end
      end
      
      class Float
        def self.tag
          :float
        end

        def parse(parse)
          Float(data) # raises ArgumentError, TypeError
        end

        def validate(repr)
          return ::Jabara.data(repr).is_a? ::Float
        end
      end

      class Schema

        attr_accessor :columns, :table_name

        def initialize
          @columns = []
        end
      end

      class Builder

        attr_reader :schema

        def initialize
          @schema = Schema.new
        end

        def self.build(&block)
          this = self.new
          this.instance_eval(&block)
          return this.schema
        end

        def self.build_from_sql(query_str)
          parser = Scheman::Parsers::Mysql.new

          create_stmt_hashs = parser.parse(query_str)
            .to_hash
            .select {|stmt| not stmt[:create_table].nil? }
            .map{|stmt| stmt[:create_table] }

          create_stmt_hashs.map { |create_stmt_hash|
            schema = stmt_to_schema(create_stmt_hash)
            [schema.table_name, schema]
          }.to_h
        end

        # 以下DSLメソッド。buildに渡すblock内で使う。

        def table_name(table_name)
          @schema.table_name = table_name
        end

        def column(key, type, *args)
          @schema.columns.push({key: key, type: type, constraints: args})
        end

        def not_null
          :not_null
        end

        def boolean
          Boolean.new
        end

        def integer
          Integer.new
        end

        def varchar(max)
          Char.new max: max
        end

        def char(max, char_set:nil)
          # TODO char_set
          Char.new max: max
        end

        def datetime
          DateTime.new
        end

        def float
          Float.new
        end

        private 

        def self.stmt_to_schema(create_stmt_hash)
          this = self.new
          this.schema.table_name = create_stmt_hash[:name]
          create_stmt_hash[:fields].each do |field_hash|
            field_hash = field_hash[:field]
            type = case field_hash[:type]
            when "char", "varchar"
              max = field_hash[:values][0]
              if max.nil? then Char.new else Char.new max: max end
            when "text"
              Text.new
            when "integer"
              max = field_hash[:values][0]
              if max.nil? then Integer.new else Integer.new max: max end
            when "boolean"
              Boolean.new
            when "double", "float"
              Float.new
            when "datetime"
              DateTime.new
            else
              raise ArgumentError, 'invalid type'
            end

            if field_hash[:qualifiers].include?({qualifier: {type: "not_null"}}) then
              this.column field_hash[:name], type, :not_null
            else
              this.column field_hash[:name], type
            end
          end

          this.schema
        end

      end

    end
  end
end

