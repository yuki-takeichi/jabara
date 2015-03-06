require 'jabara/data'
require 'jabara/transformer/flatten'

module Jabara
  module Converter
    class NestToFlats

      # inputの[object_type]とoutputsのobject_typeが一致することを仮定
      # ユースケースによるけど、input schemaのkeysとoutput schemaのcolummsはなるべく一致しているべき
      def initialize(input:, output_map:, id_key_name: 'belongsTo')
        @input = input
        @output_map = output_map # object_typeからOutputへのマッピング
        @tr_flatten = Jabara::Transformer::Flatten.new(id_key_name: id_key_name)
      end

      def convert(hash)
        nested_repr = @input.decode(hash)
        flat_repr, inner_reprs = @tr_flatten.convert(nested_repr)

        write(flat_repr)
        inner_reprs.each do |inner_repr|
          write(inner_repr)
        end
      end

      def terminate_all
        @output_map.each do |_, output|
          output.terminate
        end
      end

      private
      def write(repr)
        object_type = Jabara.object_type(repr)
        output = @output_map[object_type]
        raise ArgumentError, 'output plugin for %s is not registered' % object_type if output.nil?
        output.write(repr)
      end
    end
  end
end

