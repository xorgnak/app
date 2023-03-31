module LOGIC
  
  def self.pay chan, *users
    puts %[#{chan} #{users}]
    @chan = DB[:chan][chan]
    item = DB[:item][@chan[:item]]
    [users].flatten.each { |e|
      u = DB[:user][e]
      p, x = ("#{u[:xp].to_i}".length * @chan[:pay].to_f).to_f, "#{@chan[:xp].to_i}".length;
      amt = p + item[:pay].to_f
      u.weight[:roles].to_h.each_pair {|k,v| amt += "#{v.to_i}".length }
      puts %[pay: #{e} #{p} #{x} #{amt} ]
      u.incr(:gp, amt);
      u.weight[:gp].incr(chan, amt)
      u.incr(:xp, x);
      u.weight[:xp].incr(chan, x)
      @chan.decr(:gp, amt)
      @chan.weight[:gp].decr(e, amt)
      @chan.incr(:xp)
      @chan.weight[:xp].incr(e)
    }
  end
 
  def self.xfer h={}
    bank = DB[:chan][h[:chan]]
    from = DB[:user][h[:from]]
    to = DB[:user][h[:to]]
    amt = h[:amt] || 1
    from.decr(:gp, amt)
    from.weight[:gp].decr(h[:to], amt)
    to.incr(:gp, amt)
    to.weight[:gp].incr(h[:from], amt)
  end

  def self.role c, r, u
    puts "ROLE: #{c} #{r} #{u}"
    chan = DB[:chan][c]
    role = DB[:role][r]
    user = DB[:user][u]
    puts "ROLE: #{chan} #{role} #{user}"
    user.weight[:roles].incr(role.for)
    user.update roles: user.weight[:roles].keys.length

    role.weight[:members].incr(user.for)
    role.update members: role.weight[:members].keys.length
    
    chan.weight[:roles].incr(user.for)
    chan.update roles: chan.weight[:roles].keys.length
  end

  def self.chan c, u
    chan = DB[:chan][c]
    user = DB[:user][u]
    user.weight[:chans].incr(u)
    user.update chans: user.weight[:chans].keys.length
    chan.weight[:users].incr(c)
    chan.update users: chan.weight[:users].keys.length
  end
  
end
