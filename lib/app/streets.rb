
module STREET
  def self.[] k
    DB[:street][k]
  end
  def self.filter h={}, &b
    r = []
    DB[:street].entries.each do |key|
      h.each_pair do |hk,hv|
        if hv.class == Integer || hv.class == Float
          if DB[:street][key][hk] >= hv
            r << key
          end
        else
          if DB[:street][key][hk].include? hv
            r << key
          end
        end
      end
    end
    if block_given?
      r.uniq.each { |e|  d = DB[:street][e]; b.call(d) }
    else
      return r.uniq
    end
  end
end
