module DB
  @@DB = {}
  @@MD5 = {}
  @@SHA = {}
  @@AT = {}
  def self.md5
    @@MD5
  end
  def self.sha
    @@SHA
  end
  def self.[] k
    @@DB[k]
  end
  def self.[]= k, h={}
    @@DB[k] = Db.new(k, h)
  end
  def self.dbs
    @@DB.keys
  end

  def self.filter t, h={}, &b
    r = []
    @sort = h.delete(:sort)
    @@DB[t].entries.each do |key|
      add = {}
      h.each_pair do |hk,hv|
        puts "POOL #{t} #{key} #{hk}: #{hv}"
        if hv.class == Integer || hv.class == Float
          if @@DB[t][key][hk] >= hv; add[hk] = true; end
        else
          if @@DB[t][key][hk].include?(hv); add[hk] = true; end
        end
      end
      if add.keys == h.keys; r << @@DB[t][key]; end
    end
    r.uniq!
    if block_given?
      if @sort != nil
        rr = r.sort {|a, b| b[@sort.to_sym] <=> a[@sort.to_sym] }; a = []; rr.each { |e| a << b.call(e) }
      else
        r.each { |e| a << b.call(e) }
      end
      return a
    else
      if @sort != nil; return r.sort {|a, b| b[@sort.to_sym] <=> a[@sort.to_sym] }; else; return r; end
    end
  end
  
  class Db
    def initialize kk, h={}
      @key = kk
      @skel = h
      @tables = Hash.new { |h,k| kkk = "#{@key}-#{k}"; h[k] = Table.new(kkk, @skel) }
      @table_files = "db/#{@key}-*.store"
      #puts "Db: #{@key} #{@table_files}"
      Dir[@table_files].each { |e|
        #puts "Db: #{e}"
        if m = /db\/#{@key}-(\d+).store/.match(e);
          #puts "Db.true #{m[1]}"
          @tables[m[1]];
        end
      }
    end
    def keys
      @skel.keys
    end
    def [] k
      @tables[k]
    end
    def entries &b
      if block_given?
        @tables.keys.each {|e| b.call(@tables[e]) }
      else
        @tables.keys
      end
    end
    def tables
      @tables
    end
  end
  
  class Weight
    def initialize table, key
      @table, @key, @dir = table, key
      @db = PStore.new("db/#{table}-#{key}.store", true)
    end
    def [] k
      @db.transaction {|db| db[k] }
    end
    def keys
      @db.transaction {|db| db.keys }
    end
    def incr k, *a
      n = a[0] ? a[0] : 1
      @db.transaction do |db|
        x = db[k].to_f
        db[k] = x + n
      end
    end
    def decr k, *a
      n = a[0] ? a[0] : 1
      @db.transaction do |db|
        x = db[k].to_f
        db[k] = x - n
      end
    end
    def to_h
      h = {}
      @db.transaction { |db| db.keys.each { |e| h[e] = db[e] } }
      return h
    end
  end
  class Table
    def initialize k, h={}
      @key = k
      @type, @id = @key.split("-")
      @db = PStore.new("db/#{k}.store", true)
      @weight = Hash.new { |h,k| h[k] = Weight.new(@key, k) }
      @db.transaction do |db|
        if db.keys.length == 0
          h.each_pair { |k,v| db[k] = v; if v.class == Integer || v.class == Float; @weight[k]; end }
        else
          db.keys.each {|e| v = db[e]; if v.class == Integer || v.class == Float; @weight[e]; end }
        end
      end
    end
    def id; @key; end
    def for; @id; end
    def md5;
      x = Digest::MD5.hexdigest(@key);
      DB.md5[x] = self
      return x
    end
    def sha;
      x = Digest::SHA2.hexdigest(@key);
      DB.sha[x] = self 
      return x
    end
    def from
      @from
    end
    def to
      @to
    end
    def weight
      @weight
    end
    def weights
      @weight.keys
    end
    def keys
      @db.transaction do |db|
        db.keys
      end
    end
    def to_h
      h = { weights: Hash.new {|h,k| h[k] = @weight[k.to_sym].to_h } }
      @db.transaction do |db|
        db.keys.each {|e| v = db[e]; h[e] = v; if v.class == Integer || v.class == Float; h[:weights][e]; end }
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

DB[:host] = { head: 'head', body: 'body', img: '/bg.img', name: 'z4 instance.', desc: '', goto: '' }

DB[:user] = { xp: 0, gp: 0, lvl: 0, roles: 0, chans: 0, host: "", name: "", share: '',
              brand: '', desc: '', bookmark: '', movie: '', phone: '', items: [], places: [] }

DB[:role] = { users: 0, chans: 0 }

DB[:chan] = { name: "", desc: "", host: "", brand: "", place: "", item: "", share: '', business: '', link: '',
              verbose: false, gp: 0, val: 1, pay: 1, xp: 0, roles: 0,  lvl: 0, users: 0,
              gps: "", pos: "", until: "", place: "" }

DB[:item] = { priv: [], places: [], valid: [], level: 0, pay: 0 }

DB[:work] = { xp: 0, gp: 0 }

DB[:priv] = { can: [], cannot: [] }
DB[:place] = { crossstreets: [], gps: '', address: '', items: [],
               areas: [], types: [], ammenities: [], affluence: 0, scans: 0, returns: 0, affinity: 0, influence: 0, busy: 0, size: 0 }
DB[:street] = {}
DB[:area] = { intersections: [] }
DB[:intersection] = { affluence: 0, scans: 0, returns: 0, areas: [], places: [] }

DB[:event] = { name: '', desc: '', ends: 0, begins: 0, places: [] }
