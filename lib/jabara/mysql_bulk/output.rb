require 'jabara/data'
require 'jabara/mysql/output'

module Jabara
  module MySQLBulk
    class Output < Jabara::MySQL::Output
      def initialize(schema:, tuple_size:1000)
        @table_name = schema.table_name
        @schema = schema
        @tuple_size = tuple_size
        reset_buffer
      end

      def encode(repr)
        data = ::Jabara.data(repr)
        tuple_str = "(%s)" % @schema.columns.map { |column| 
          key = column[:key]
          mysql_value(data[key])
        }.join(", ")

        @buf << tuple_str
        @buf << ","
        @tuple_count = @tuple_count + 1

        if @tuple_count >= @tuple_size then
          return flush
        else 
          return nil
        end
      end

      def flush
        return nil if @tuple_count == 0

        terminate
        ret = @buf
        reset_buffer
        return ret
      end

      def reset_buffer
        @buf = insert_head
        @tuple_count = 0
      end

      def terminate
        @buf.chop!
        @buf << ";\n"
      end

      def insert_head
        "insert into `%s` %s values" % [@table_name, column_def]
      end

      def column_def
        "(%s)" % @schema.columns.map {|column| "`%s`" % column[:key] }.join(", ")
      end

      def validate
        @schema.columns.each do |column|
          return false, 'violate "not null" constraint.' if column[:constraints].include? :not_null and data.nil?
          valid, err = column[:type].validate(data)
          return false, err unless valid
        end

        return true, nil
      end
    end
  end
end
