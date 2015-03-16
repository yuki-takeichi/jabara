require 'jabara/data'

module Jabara
  module MySQL
    class Output

      def initialize(null_value:'null')
        @null_value = null_value
      end

      def encode(object_repr)
        table_name = ::Jabara.object_type(object_repr)
        mysql_value_hash = {}
        ::Jabara.data(object_repr).each do |key, repr|
          mysql_value_hash[key] = mysql_value(repr)
        end
        build_insert_query(table_name, mysql_value_hash)
      end

      private
      def quote(str)
        # MySQL の nobackquote_escape option が false であることが前提
        '"%s"' % str.gsub('"', '""').gsub(/\\/, "\\\\\\") # \ を \\ に置き換える
      end

      # Jabara中間表現をMySQL表現に変換する
      def mysql_value(repr)
        raise ArgumentError, 'repr must not be nil' if repr.nil?

        data = ::Jabara.data(repr)
        tag = ::Jabara.tag(repr)
        case tag
        when :null
          @null_value
        when :integer
          data
        when :float
          data
        when :datetime
          quote(data.strftime("%Y-%m-%d %H:%M:%S"))
        when :string
          quote(data)
        when :boolean
          if data == true then '1' else '0' end
        when :object, :array
          raise ArgumentError, "Can't accept nested object or array!"
        else
          raise ArgumentError, "Invalid tag was found: %s" % tag
        end
      end

      # Insertクエリを生成する
      def build_insert_query(table_name, mysql_repr)
        cols = []
        vals = []
        mysql_repr.each do |column, value|
          cols << column
          vals << value
        end
        "insert into %s (%s) values(%s);\n" % [table_name, cols.join(', '), vals.join(', ')]
      end
    end
  end
end

