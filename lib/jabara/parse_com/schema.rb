require 'jabara/data'
require 'jabara/transformer/key_value'

require 'date'

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

      class TimeStamp # Parseが自動生成するカラム (createdAt, updatedAt)
        def parse(data)
          datetime = ::DateTime.iso8601(data)
          ::Jabara.primitive(:datetime, datetime)
        end
      end

      class Integer
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
      end

      class Float
        def initialize(default: nil) # default = nil の場合はnullを許容する
          raise TypeError, 'default must be integer' unless default.is_a? ::Float or default.nil?
          @default = default
        end

        def parse(data)
          return ::Jabara.null if data.nil? and @default.nil?
          return ::Jabara.primitive(:float, @default) if data.nil?

          raise TypeError, 'default must be float' unless data.is_a? ::Float
          ::Jabara.primitive(:float, data)
        end
      end

      class ObjectId
        def parse(data)
          ::Jabara.primitive(:string, data)
        end
      end

      class File
        def parse(data)
          return ::Jabara.null if data.nil?
          raise ArgumentError, 'File object is collapsed' if data['url'].nil?
          ::Jabara.primitive(:string, data['url'])
        end
      end

      class DateTime
        def initialize(default: nil) # default = nil の場合はnullを許容する
          raise TypeError, 'default must be datetime' unless default.is_a? ::DateTime or default.nil?
          @default = default
        end

        def parse(data)
          return ::Jabara.null if data.nil? and @default.nil?
          raise ArgumentError, 'datetime object is collapsed' if data['iso'].nil?
          ::Jabara.primitive(:datetime, ::DateTime.iso8601(data['iso']))
        end
      end

      class String
        def initialize(max: 1000, default: nil) # default = nil の場合はnullを許容する
          raise TypeError, 'default must be string' unless default.is_a? ::String or default.nil?
          raise TypeError, 'max must be integer' unless max.is_a? ::Integer
          @max = max
          @default = default
        end

        def parse(data)
          return ::Jabara.null if data.nil? and @default.nil?
          return @default if data.nil?
          raise TypeError, 'data must be string' unless data.is_a? ::String or default.nil?
          ::Jabara.primitive(:string, data.slice(0, @max))
        end
      end

      class Pointer
        def parse(data)
          return ::Jabara.null if data.nil?
          raise ArgumentError, 'pointer object is collapsed' if data['objectId'].nil?
          ::Jabara.primitive(:string, data['objectId'])
        end
      end

      class Boolean
        def initialize(default: nil) # default = nil の場合はnullを許容する
          raise ArgumentError, 'default must be true of false' unless [true, false].include? default
          @default = default
        end

        def parse(data)
          return ::Jabara.null if data.nil? and @default.nil?
          return ::Jabara.primitive(:boolean, @default) if data.nil?
          raise TypeError, 'data must be true or false' unless [true, false].include? data
          ::Jabara.primitive(:boolean, data)
        end
      end

      class ACL
        def initialize user_acl_object_type: , role_acl_object_type:
          @user_acl_object_type = user_acl_object_type
          @role_acl_object_type = role_acl_object_type
        end

        def parse(data)
          return ::Jabara.set([]) if hash.nil?
          elems = ::Jabara::Transformer::KeyValue.new.to_entries(hash).map {|entry|
            if entry[:key].start_with? 'role:' then
              decode_acl_role_entry(entry[:key].gsub(/role:/, ''), entry[:value])
            else
              decode_acl_user_entry(entry[:key], entry[:value])
            end
          }

          return ::Jabara.set(elems)
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
      end

      class Schema

        attr_accessor :key_defs, :object_type, :id_key_name

        def initialize
          @key_defs = {}
          @object_type = nil
          @id_key_name = nil
        end

      end

      class Builder

        attr_reader :schema

        def self.build(&block)
          this = Builder.new
          this.instance_eval(&block)
          return this.schema
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

        def string max: 1000, default: nil
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
      end
    end
  end
end