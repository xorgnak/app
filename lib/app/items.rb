
module ITEM
  def self.[] k
    DB[:item][k]
  end
  def self.valid? k
    valid = false
    DB[:item][k][:valid].each do |cond|
      self.instance_eval(%[if #{cond}; valid = true; end])
    end
    return valid
  end
  def self.filter h={}, &b
    LOGIC.filter :item, h, b
  end
end
