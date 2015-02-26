require 'jabara/data'

module Jabara
  module Transformer
    class Nest
      def convert(repr_hash, inner_repr_hash, key_string)
        raise ArgumentError, 'key_string must be string' unless key_string.is_a? ::String
        repr_hash[key_string] = inner_repr_hash
      end
    end
  end
end

