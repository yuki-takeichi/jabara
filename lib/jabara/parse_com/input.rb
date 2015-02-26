require 'jabara/data'

module Jabara
  module ParseCom
    class Input
      def initialize(parse_com_schema)
        @schema = parse_com_schema
      end

      # ParseObjectをJabara中間表現のobjectに変換する
      def decode(hash)
        data = {}
        @schema.key_defs.each do |key, parser|
          data[key] = parser.parse(hash[key]) # raises ArgumentError
        end
        id = ::Jabara.primitive(:string, hash[@schema.id_key_name])
        return ::Jabara.object(@schema.object_type, data, id)
      end
    end
  end
end
