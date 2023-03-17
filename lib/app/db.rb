module DB
  @@DB = {}
  def self.[] k
    @@DB[k]
  end
  def self.[]= k, h={}
    @@DB[k] = Db.new(k, h)
  end
  def self.dbs
    @@DB.keys
  end
  class Db
    def initialize kk, h={}
      @key = kk
      @skel = h
      @tables = Hash.new { |h,k| kkk = "#{@key}-#{k}"; h[k] = Table.new(kkk, @skel) }
    end
    def [] k
      @tables[k]
    end
    def entries
      @tables.keys
    end
  end
  class Table
    def initialize k, h={}
      @db = PStore.new("db/#{k}.store", true)
      @db.transaction do |db|
        if db.keys.length == 0
          h.each_pair { |k,v| db[k] = v }
        end
      end
    end
    def keys
      @db.transaction do |db|
        db.keys
      end
    end
    def to_h
      h = {}
      @db.transaction do |db|
        db.keys.each {|e| h[e] = db[e] }
      end
      return h
    end
    def [] k
      @db.transaction do |db|
        db[k]
      end
    end
    def incr k, *a
      if a[0]
        y = a[0].to_f
      else
        y = 1
      end
      @db.transaction do |db|
        x = db[k].to_f
        db[k] = x + y
      end
    end
    def decr k, *a
      if a[0]
        y = a[0].to_f
      else
        y = 1
      end
      @db.transaction do |db|
        x = db[k].to_f
        db[k] = x - y
      end
    end
    def update h={}
      @db.transaction do |db|
        h.each_pair { |k,v| db[k] = v }
      end
    end
    def do k, &b
      @db.transaction do |db|
        b.call(db)
      end
    end
  end
end

DB[:user] = { xp: 0, gp: 0, name: "promotor" }
DB[:chan] = { brand: "", item: "", gp: 0, val: 1, pay: 1, xp: 0, gps: "", pos: "", until: "", place: "" }

