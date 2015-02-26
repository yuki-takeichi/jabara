module Jabara
  module Transformer

    # inspired by jq 'to_entries', 'from_entries' and 'with_entries' functions
    # http://stedolan.github.io/jq/manual/
    class KeyValue

      #def from_entries()
      #end

      def to_entries(hash)
        entries = []
        hash.each do |key, value|
          entry = {:key => key, :value => value}
          entries.push(entry)
        end
        return entries
      end

      #def with_entries()
      #end

    end
  end
end
