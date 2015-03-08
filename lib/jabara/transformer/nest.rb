require 'jabara/data'

module Jabara
  module Transformer
    class Nest
      def convert(outer_repr:, inner_repr:, target_key_name:, id_key_name:'id', object_type:)
        case object_type
        when :object
          Jabara.set_data(outer_repr, denormalize(outer_repr: outer_repr,
                                                  inner_repr: inner_repr,
                                                  target_key_name: target_key_name,
                                                  id_key_name: id_key_name))
        when :array
          Jabara.array(outer_repr, Jabara.data(inner_repr).map {|repr|
            denormalize(outer_repr: outer_repr,
                        inner_repr: repr,
                        target_key_name: target_key_name,
                        id_key_name: id_key_name)
          }
        when :set
          Jabara.set(outer_repr, Jabara.data(inner_repr).map {|repr|
            denormalize(outer_repr: outer_repr,
                        inner_repr: repr,
                        target_key_name: target_key_name,
                        id_key_name: id_key_name)
          }
        end
      end

      def denoramalize(outer_repr:, inner_repr:, target_key_name:, id_key_name:'id', object_type:)
        raise ArgumentError, 'outer objectId must be equal to inner id_key_name' unless Jabara.data(inner_repr)[id_key_name] == Jabara.id(outer_repr)
        inner_data = Jabara.data(inner_repr)
        inner_data.delete(id_key_name)
        Jabara.data(outer_repr)[target_key_name] = inner_data
      end
    end
  end
end

