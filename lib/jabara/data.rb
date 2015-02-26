module Jabara
  # Jabara中間表現のためのコンストラクタ/アクセサ
  # 抽象データ型なので、Plugin側からIndexを渡して直接Arrayにアクセスするのは禁止
  
  # コンストラクタ
  
  def self.primitive(tag, data)
    [tag, data]
  end

  def self.null
    [:null]
  end

  def self.object(object_type, data, id=nil)
    [:object, data, object_type, id]
  end

  def self.array(reprs)
    [:array, reprs]
  end

  def self.set(reprs)
    [:set, reprs]
  end

  def self.tag(repr)
    repr[0]
  end

  # アクセサ

  def self.data(repr)
    repr[1]
  end

  def self.set_data(repr, data)
    repr[1] = data
  end

  # use only for :object
  def self.object_type(repr)
    repr[2]
  end

  def self.primitive?(repr)
    tag = self.tag(repr)
    not [:array, :object, :set].include?(tag)
  end

  # use only for :object
  def self.id(repr)
    return nil if repr.length < 4
    return repr[3]
  end
end
