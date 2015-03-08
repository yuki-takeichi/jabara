require 'jabara/data'
require 'jabara/transformer/key_value'

require 'date'
require 'yajl'
require 'uri'

module Jabara
  module ParseCom
    module Schema

      # TODO
      #class Object
      #  def parse(data)
      #    ::Jabara.object(...)
      #  end
      #end

      # TODO
      #class Array
      #  def parse(data)
      #     ::Jabara.array(...array...)
      #  end
      #end

      class PrimitiveParser
        def object_types
          []
        end
      end

      class TimeStamp < PrimitiveParser # Parseが自動生成するカラム (createdAt, updatedAt)
        def parse(data)
          datetime = ::DateTime.iso8601(data)
          ::Jabara.primitive(:datetime, datetime)
        end

        def reverse(repr) # TODO schema と parser は分離しないと
          raise ArgumentError, 'repr must be datetime' unless Jabara.tag(repr) == :boolean
          data = Jabara.data(repr)
          raise ArgumentError, 'timestamp field not allowed to be null' if data.nil?
          data.iso8601
        end
      end

      class Integer < PrimitiveParser
        def initialize(default: nil) # default = nil の場合はnullを許容する
          raise TypeError, 'default must be integer' unless default.is_a? ::Integer or default.nil?
          @default = default
        end

        def parse(data)
          return ::Jabara.null if data.nil? and @default.nil?
          return ::Jabara.primitive(:integer, @default) if data.nil?

          raise TypeError, 'default must be integer' unless data.is_a? ::Integer
          ::Jabara.primitive(:integer, data)
        end

        def reverse(repr)
          return nil if repr.nil? and @default.nil?
          return @default if repr.nil?
          raise ArgumentError, 'repr must be integer' unless Jabara.tag(repr) == :integer
          Jabara.data(repr)
        end
      end

      class Float < PrimitiveParser
        def initialize(default: nil) # default = nil の場合はnullを許容する
          raise TypeError, 'default must be integer' unless default.is_a? ::Float or default.nil?
          @default = default
        end

        def parse(data)
          return ::Jabara.null if data.nil? and @default.nil?
          return ::Jabara.primitive(:float, @default) if data.nil?

          raise TypeError, 'default must be float' unless data.is_a? ::Float
          Jabara.primitive(:float, data)
        end

        def reverse(repr)
          return nil if repr.nil? and @default.nil?
          return @default if repr.nil?
          raise ArgumentError, 'repr must be float' unless Jabara.tag(repr) == :float
          Jabara.data(repr)
        end
      end

      class ObjectId < PrimitiveParser
        def parse(data)
          Jabara.primitive(:string, data)
        end

        def reverse(repr)
          Jabara.data(repr)
        end

        def reverse_validate(repr)
          raise ArgumentError, 'repr must not be nil' if repr.nil?
        end
      end

      class File < PrimitiveParser
        def parse(data)
          return ::Jabara.null if data.nil?
          raise ArgumentError, 'File object is collapsed' if data['url'].nil?
          ::Jabara.primitive(:string, data['url'])
        end

        def reverse(repr)
          return nil if repr.nil?
          name = repr.split('/').last
          url = Jabara.data(repr)
          {'__type' => 'File',
           'name' => name,
           'url' => url}
        end

        def reverse_validate(repr)
          raise ArgumentError, 'repr must be string' unless Jabara.tag(repr) == :string
          raise ArgumentError, 'not valid parse file url' unless Jabara.data(repr).start_with?('http://files.parsetfss.com/')
        end
      end

      class DateTime < PrimitiveParser
        def initialize(default: nil) # default = nil の場合はnullを許容する
          raise TypeError, 'default must be datetime' unless default.is_a? ::DateTime or default.nil?
          @default = default
        end

        def parse(data)
          return ::Jabara.null if data.nil? and @default.nil?
          raise ArgumentError, 'datetime object is collapsed' if data['iso'].nil?
          ::Jabara.primitive(:datetime, ::DateTime.iso8601(data['iso']))
        end

        def reverse(repr)
          return nil if repr.nil? and @default.nil?
          data = if repr.nil? then @default else Jabara.data(repr) end
          {'__type' => 'Date',
           'iso' => data.iso8601}
        end

        def reverse_validate(repr)
          raise ArgumentError, 'repr must be datetime' unless Jabara.tag(repr) == :datetime
        end
      end

      class String < PrimitiveParser
        def initialize(max: nil, default: nil) # default = nil の場合はnullを許容する
          raise TypeError, 'default must be string' unless default.is_a? ::String or default.nil?
          raise TypeError, 'max must be integer' unless max.is_a? ::Integer or max.nil?
          @max = max
          @default = default
        end

        def parse(data)
          return ::Jabara.null if data.nil? and @default.nil?
          return @default if data.nil?
          raise TypeError, 'data must be string' unless data.is_a? ::String or default.nil?
          data = data.slice(0, @max) unless @max.nil?
          ::Jabara.primitive(:string, data)
        end
      end

      class Pointer < PrimitiveParser
        def parse(data)
          return ::Jabara.null if data.nil?
          raise ArgumentError, 'pointer object is collapsed' if data['objectId'].nil?
          ::Jabara.primitive(:string, data['objectId'])
        end

        def reverse(repr)
          object_id = Jabara.data(repr)
          {'__type' => 'Pointer',
           'className' => className, # TODO
           'objectId' => object_id}
        end

        def reverse_validate(repr)
          raise ArgumentError, 'data must be string' unless Jabara.tag(repr) == :string
          raise ArgumentError, 'data must be valid object id' if /[0-9a-zA-Z]{10}/.match(Jabara.data(repr)).nil?
        end
      end

      class Boolean < PrimitiveParser
        def initialize(default: nil) # default = nil の場合はnullを許容する
          raise ArgumentError, 'default must be true of false' unless [true, false].include? default or default.nil?
          @default = default
        end

        def parse(data)
          return ::Jabara.null if data.nil? and @default.nil?
          return ::Jabara.primitive(:boolean, @default) if data.nil?
          raise TypeError, 'data must be true or false' unless [true, false].include? data
          ::Jabara.primitive(:boolean, data)
        end

        def reverse(repr)
          return nil if repr.nil? and @default.nil?
          return @default if repr.nil?
          raise ArgumentError, 'repr must be boolean' unless Jabara.tag(repr) == :boolean
          Jabara.data(repr)
        end
      end

      class ACL # 抽象化が破れているので、中身のobjectを触る時はinput or outputを使う (or その構造をリファクタする)
        def initialize user_acl_object_type: , role_acl_object_type:
          @user_acl_object_type = user_acl_object_type
          @role_acl_object_type = role_acl_object_type
        end

        def parse(data)
          return ::Jabara.set([]) if data.nil?
          elems = ::Jabara::Transformer::KeyValue.new.to_entries(data).map {|entry|
            if entry[:key].start_with? 'role:' then
              decode_acl_role_entry(entry[:key].gsub(/^role:/, ''), entry[:value])
            else
              decode_acl_user_entry(entry[:key], entry[:value])
            end
          }

          return ::Jabara.set(elems)
        end

        def object_types
          [@user_acl_object_type, @role_acl_object_type]
        end

        def decode_acl_user_entry(user_object_id, acl_permission)
          data = {}
          data['userObjectId'] = ::Jabara.primitive(:string, user_object_id)
          data['read'] = ::Jabara.primitive(:boolean, acl_permission['read'] || false)
          data['write'] = ::Jabara.primitive(:boolean, acl_permission['write'] || false)
          ::Jabara.object(@user_acl_object_type, data)
        end

        def decode_acl_role_entry(role_name, acl_permission)
          data = {}
          data['roleName'] = ::Jabara.primitive(:string, role_name)
          data['read'] = ::Jabara.primitive(:boolean, acl_permission['read'] || false)
          data['write'] = ::Jabara.primitive(:boolean, acl_permission['write'] || false)
          ::Jabara.object(@role_acl_object_type, data)
        end

        def reverse(repr)
          raise ArgumentError, 'repr must be set' unless Jabara.tag(repr) == :set
          raise ArgumentError, 'inner data must be array' unless Jabara(data).is_a? ::Array
          Jabara.data(repr).map {|repr|
            raise ArgumentError, 'inner repr must be object' unless Jabara.tag(repr) == :object
            data = Jabara.data(repr)

            key = case Jabara.object_type(repr)
            when @user_acl_object_type
              data['userObjectId']
            when @role_acl_object_type
              'role:' + data['roleName']
            else
              raise ArgumentError, 'inner repr must have valid object type'
            end

            value = {}
            value['read'] = data['read'] unless data['read'].nil?
            value['write'] = data['write'] unless data['write'].nil?

            if value.empty? then [] else [key, value] end
          }.to_h
        end
      end

      class JSONString < PrimitiveParser
        def initialize
          @encoder = Yajl::Encoder.new
          @paraser = Yajl::Parser.new
        end

        def parse(data)
          return ::Jabara.null if data.nil?
          raise ArgumentError, 'data must be hash or array' unless data.is_a? ::Hash or data.is_a? ::Array

          json_str = @encoder.encode(data)
          Jabara.primitive(:string, json_str)
        end

        def reverse(repr)
          raise ArgumentError, 'repr must be string' unless Jabara.tag(repr) == :string
          @parser.parse(Jabara.data(repr))
        end
      end

      class Variants
        def initialize(&block)
          @variants = {}
          instance_eval(&block)
        end

        def parse(data)
          return ::Jabara.null if data.nil?
          raise ArgumentError, 'data must be hash' unless data.is_a? ::Hash

          reprs = @variants.map { |key, schema|
            if not data[key].nil? then schema.decode(data[key]) else nil end
          }.compact
          ::Jabara.set(reprs)
        end

        def object_types
          @variants.map { |_, input|
            [input.schema.object_type] + input.schema.inner_object_types
          }.flatten
        end

        def reverse(repr)
          raise ArgumentError, 'repr must be set' unless Jabara.tag(repr) == :set
          Jabara.data(repr).map {|repr|
            key = Jabara.object_type(repr)
            data = Jabara.data(repr)
            [key, @variants[key].reverse(data)] # TODO reverseが使えない...
          }.to_h
        end

        # following methods are for DSL

        def variant(key:, schema:)
          @variants[key] = ::Jabara::ParseCom::Input.new(schema)
        end

        def schema(&block)
          Builder.build(&block)
        end
      end

      class Schema

        attr_accessor :key_defs, :object_type, :id_key_name

        def initialize
          @key_defs = {}
          @object_type = nil
          @id_key_name = nil
        end

        def inner_object_types
          @key_defs.map { |key_string, schema|
            schema.object_types
          }.flatten
        end

      end

      class Builder

        attr_reader :schema

        def self.build(&block)
          this = self.new
          this.instance_eval(&block)
          return this.schema
        end
 
        def self.relation object_type
          self.build do
            type object_type
            key 'owningId',  string
            key 'relatedId', string
          end
        end

        def initialize
          @schema = Schema.new
        end

        # 以下DSLメソッド。buildに渡すblock内で使う。
        
        # オブジェクトのtype
        def type(object_type)
          @schema.object_type = object_type
        end

        def id(id_key_name)
          @schema.id_key_name = id_key_name
        end

        # スキーマにキーを登録する
        def key(key_string, type)
          raise ArgumentError, 'key_name must be string' unless key_string.is_a? ::String
          (@schema.key_defs)[key_string] = type
        end

        # TODO
        #def object
        #  Object.new
        #end

        # TODO
        #def array
        #  Array.new
        #end

        def timestamp
          TimeStamp.new
        end

        def integer default: nil
          Integer.new default: default
        end

        def float default: nil
          Float.new default: default
        end

        def parse_object_id
          ObjectId.new
        end

        def file
          File.new
        end

        def datetime default: nil
          DateTime.new default: default
        end

        def string max: nil, default: nil
          String.new max: max, default: default
        end

        def pointer
          Pointer.new
        end

        def boolean default: nil
          Boolean.new default: default
        end

        def acl user_acl_object_type: ,role_acl_object_type:
          ACL.new(user_acl_object_type: user_acl_object_type, role_acl_object_type: role_acl_object_type)
        end

        def json_string
          JSONString.new
        end

        def variants(&block)
          Variants.new(&block)
        end
      end
    end
  end
end
