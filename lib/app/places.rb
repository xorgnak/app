
module HERE
  def self.[] k
    DB[:place][k]
  end

  def self.places
    DB[:place].entries
  end
  
  def self.make k, h
    d = DB[:place][k]
    xs_1 = CITY[h[:crossstreets][0]][h[:crossstreets][1]]
    xsp_1 = xs_1.db[:places]
    xsa_1 = xs_1.db[:areas]
    xs_1.db.update places: [xsp_1, k].flatten.uniq, areas: [xsa_1, h[:areas]].flatten.uniq
    xs_2 = CITY[h[:crossstreets][1]][h[:crossstreets][0]]
    xsp_2 = xs_2.db[:places]
    xsa_2 = xs_2.db[:areas]
    xs_2.db.update places: [xsp_2, k].flatten.uniq, areas: [xsa_2, h[:areas]].flatten.uniq
    d.update h
  end
  
  def self.filter h={}, &b
    DB.filter :place, h, b
  end
end

