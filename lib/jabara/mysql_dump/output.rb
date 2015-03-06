require 'jabara/data'

module Jabara
  module MySQLDump
    class Output < Jabara::MySQL::Output

      def initialize(schema:, out_path:,
                     fields_terminated_by:',',
                     fields_enclosed_by:'"', # TODO Not supported yet
                     fields_escapted_by:'"', # TODO Not supported yet
                     lines_terminated_by:"\n")
        @schema = schema
        @out_path = out_path

        @field_delimiter = fields_terminated_by
        @field_quote_str = fields_enclosed_by
        @escape_str = fields_escapted_by
        @line_delimiter = lines_terminated_by

        @column_keys = @schema.columns.map { |column| column[:key] }
        @file = File.open(@out_path, 'w')
        @buf = ''
      end

      def write(object_repr)
        begin
          @file.write(@buf)
          data = ::Jabara.data(object_repr)
          @buf = @column_keys.map { |key|
            mysql_value(data[key])
          }.join(@field_delimiter) + @line_delimiter
        rescue => e
          cleanup
          raise e # reraise
        end
      end

      def terminate
        @file.write(@buf.chomp(@line_delimiter))
        @file.close
      end

      def load_data_query
        query = <<SQL
load data infile '%s' into `%s`
character set %s
fields terminated by '%s'
       enclosed by '%s'
       escaped by '%s'
lines terminated by '%s'
;
SQL
        query % [@out_path,
                 @schema.table_name,
                 @char_set || 'utf8mb4',
                 @field_delimiter,
                 @field_quote_str,
                 @escape_str,
                 @line_delimiter]
      end

      private
      def cleanup
        @file.close
        File.delete(@out_path)
      end

    end
  end
end
