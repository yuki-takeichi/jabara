require 'jabara/data'

module Jabara
  module Transformer

    # TODO array と set のflat化は別クラスに責務を切り出した方がいいかも
    class Flatten
      def initialize(id_key_name: 'id', index_key_name: 'index')
        @id_key_name = id_key_name
        @index_key_name = index_key_name
      end

      # 与えられたオブジェクトを第1正規化する
      def convert(object_repr)
        new_repr_hash = {}
        divided_reprs = []

        id = ::Jabara.id(object_repr)
        ::Jabara.data(object_repr).each do |key, repr|
          data = ::Jabara.data(repr)
          if ::Jabara.primitive?(repr) then
            new_repr_hash[key] = repr
          else
            tag = ::Jabara.tag(repr)
            case tag
            when :object
              _object_repr = data
              ::Jabara.data(_object_repr)[@id_key_name] = id
              divided_reprs.push(_object_repr)
            when :array
              # TODO ヘテロな要素が来るケースへの対応
              # TODO primitiveな要素が来るケースへの対応

              ar = data
              ar.each_with_index do |_object_repr, index|
                ::Jabara.data(_object_repr)[@id_key_name] = id
                ::Jabara.data(_object_repr)[@index_key_name] = index
                divided_reprs.push(_object_repr)
              end
            when :set
              # TODO ヘテロな要素が来るケースへの対応
              # TODO primitiveな要素が来るケースへの対応

              st = data
              st.each do |_object_repr|
                ::Jabara.data(_object_repr)[@id_key_name] = id
                divided_reprs.push(_object_repr)
              end
            else
              raise ArgumentError, "Invalid tag was found :%s" % tag
            end
          end
        end

        ::Jabara.set_data(object_repr, new_repr_hash)
        return object_repr, divided_reprs
      end
    end
  end
end

