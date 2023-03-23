
module PRIV
  def self.[] k
    DB[:priv][k]
  end
  def self.filter h={}, &b
    r = []
    DB[:priv].entries.each do |key|
      h.each_pair do |hk,hv|
        if hv.class == Integer || hv.class == Float
          if DB[:priv][key][hk] >= hv
            r << key
          end
        else
          if DB[:priv][key][hk].include? hv
            r << key
          end
        end
      end
    end
    if block_given?
      r.uniq.each { |e|  d = DB[:priv][e]; b.call(d) }
    else
      return r.uniq
    end
  end
end
