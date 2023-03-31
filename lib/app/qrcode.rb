module QR
  @@QR = Hash.new {|h,k| h[k] = Qr.new(k) }
  def self.[] k
    @@QR[k]
  end
  def self.entries
    @@QR.keys
  end
  def self.scan u
    if m = /https:\/\/(.*)/.match(u)
      puts "QR.scan #{m[1]}"
      r = m[1].split('/')
      puts "QR.scan r #{r}"
      q = r[1].split('?')
      puts "QR.scan q #{q}"
      h = { host: r[0], view: q[0], params: {} }
      [q[1].split('&')].flatten.each { |e|
        puts "QR.scan e #{e}"
        x = e.split('=');
        puts "QR.scan x #{x}"
        h[:params][x[0]] = x[1];
      }
      return h
    else
      return false
    end
  end
  class Qr
    def initialize t
      @route = t
    end
    def work
      DB[:work][@route]
    end
    
    def route h={}
      x = Digest::MD5.hexdigest(JSON.generate(h));
      work.weight[:xp].incr x
      work.incr :xp
      CORE[x] = h
      rt = [%[?qr=#{x}]]

      if h.has_key? 'visitor'
        rt << %[&visitor=#{h['visitor']}]
      end

      if h.has_key? 'origin'
        rt << %[&origin=#{h['origin']}]
      else
        rt << %[&origin=#{CORE.now.to_i}]
      end
      
      return rt.join("")
    end
  end
end
