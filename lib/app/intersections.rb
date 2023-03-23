
module CITY
  @@STREET = Hash.new { |h,k| h[k] = Street.new(k) }
  def self.[] k
    @@STREET[k]
  end
  def self.keys
    @@STREET.keys
  end
  def self.to_h
    h = {}
    @@STREET.each_pair {|k,v| h[k] = v.to_h }
    return h
  end
  class X
    def initialize k
      @db = DB[:intersection][k]
    end
    def places
      @db[:places]
    end
    def areas
      @db[:areas]
    end
    def db
      @db
    end
    def to_h
      @db.to_h
    end
    def [] k
      HERE[k]
    end
  end
  class Street
    def initialize s
      @id = s
      @x = Hash.new { |h,k| kk = "#{@id}&#{k}"; h[k] = X.new(kk) }
      @db = DB[:street][@id]
    end
    def [] k
      @x[k]
    end
    def id
      @id
    end
    def db
      @db
    end
    def to_h
      h = {}
      @x.each_pair {|k,v| h[k] = v.to_h }
      return h
    end
  end
end
