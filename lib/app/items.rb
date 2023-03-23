
module ITEM
  def self.[] k
    DB[:item][k]
  end
  def self.filter h={}, &b
    r = []
    DB[:item].entries.each do |key|
      h.each_pair do |hk,hv|
        if hv.class == Integer || hv.class == Float
          if DB[:item][key][hk] >= hv
            r << key
          end
        else
          if DB[:item][key][hk].include? hv
            r << key
          end
        end
      end
    end
    if block_given?
      r.uniq.each { |e|  d = DB[:item][e]; b.call(d) }
    else
      return r.uniq
    end
  end
end
