
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
    @sort = h.delete(:sort)
    DB[:place].entries.each do |key|
      add = {}
      h.each_pair do |hk,hv|
        puts "#{key} #{hk}: #{hv}"
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
        r << DB[:place][key]
      end
    end
    r.uniq!
    if block_given?
      if @sort != nil
        rr = r.sort {|a, b| b[@sort.to_sym] <=> a[@sort.to_sym] }
        a = []; rr.each { |e| a << b.call(e) }
      else
        r.each { |e| a << b.call(e) }
      end
      return a
    else
      if @sort != nil
        return r.sort {|a, b| b[@sort.to_sym] <=> a[@sort.to_sym] }
      else
        return r
      end
    end
  end
end

