
module HERE
  def self.[] k
    DB[:place][k]
  end
    
  def self.make k, h
    d = DB[:place][k]
    xs = CITY[h[:crossstreets][0]][h[:crossstreets][1]]
    xsp = xs.db[:places]
    xsa = xs.db[:areas]
    xs.db.update places: [xsp, k].flatten.uniq, areas: [xsa, h[:areas]].flatten.uniq
    d.update h
  end
  
  def self.filter h={}, &b
    r = []
    DB[:place].entries.each do |key|
      add = {}
      h.each_pair do |hk,hv|
        if hv.class == Integer || hv.class == Float
          if DB[:place][key][hk] >= hv
            add[hk] = true
          end
        else
          if DB[:place][key][hk].include? hv
            add[hk] = true
          end
        end
      end
      if add.keys == h.keys
        r << key
      end
    end
    if block_given?
      r.uniq.each { |e|  d = DB[:place][e]; b.call(d) }
    else
      return r.uniq
    end
  end
end

