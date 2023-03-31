module CORE
  module WORK
    @@WORK = PStore.new("db/work.store")
    def self.[] k
      @@WORK.transaction {|db| db[k] }
    end
    def []= k,v
      @@WORK.transaction {|db| db[k] = v }
    end
    def entries
      @@WORK.transaction {|db| db.keys }
    end
    def self.has_key? k
      @@WORK.transaction do |db|
        if db.keys.include? k
          return true
        else
          return false
        end
      end
    end
  end
  @@CORE = PStore.new("db/core.store")
  LVLS = [
    :visitor,
    :influencer,
    :promotor,
    :ambassador,
    :agent,
    :operator
  ]
  COLORS = [
    'white',
    'yellow',
    'green',
    'blue',
    'purple',
    'red',
    'grey'
  ]
  PIP = [
    'check_box_outline_blank',
    'circle',
    'star',
    'grade',
    'hotel_class',
    'stars'
  ]
  def self.[] k
    @@CORE.transaction {|db| db[k] }
  end
  def self.[]= k,v
    @@CORE.transaction {|db| db[k] = v }
  end
  def self.core
    @@CORE
  end
  def self.entries
    @@CORE.transaction {|db| db.keys }
  end
  def self.has_key? k
    @@CORE.transaction do |db|
      if db.keys.include? k
        return true
      else
        return false
      end
    end
  end
  def self.color n
    nn = n - 1
    if nn.to_i > COLORS.length
      COLORS[-1]
    elsif nn.to_i < 0
      COLORS[0]
    else
      COLORS[nn]
    end
  end
  def self.pip n
    PIP[n]
  end
  def self.level n
    "#{n}".length
  end
  def self.levels
    LVLS
  end  
  def self.now
    Time.now.utc
  end
  def self.chunk(string, size)
    (0..(string.length-1)/size).map{|i|string[i*size,size]}
  end
end
