module LOGIC
  # pay rate: xp factor * channel base
  # xp rate: 
  def self.pay chan, *users
    @chan = DB[:chan][chan]
    users.each { |e|
      u = DB[:user][e];
      u.incr(:gp, ("#{u[:xp].to_i}".length * @chan[:pay].to_f).to_f);
      u.incr(:xp, "#{@chan[:xp].to_i}".length);
      @chan.decr(:gp, @chan[:pay])
      @chan.incr(:xp)
    }
  end
end
