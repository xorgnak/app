module BOT
  @@MSG = {}
  def self.message regexp, &b
    @@MSG[regexp] = b
  end
  
  @@CB = {}
  def self.command regexp, &b
    @@CB[regexp] = b
  end
  
  @@BOT = Discordrb::Bot.new token: ENV['DISCORD_TOKEN']
  @@BOT.message() do |event|
    if event.channel.name == event.user.name
      @user = DB[:user][Digest::SHA2.hexdigest("#{event.user.id}")]
      o = ["=^.^= BOT #{event.channel.name}"]
      @@MSG.each_pair { |k,v| if m = /#{k}/.match(event.content); o << v.call(event, m); end }
      #    if o.length > 1
      event.respond %[#{o.join("\n")}]
      #    end
    end
  end
  
  @@CMD = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], prefix: '#'
  @@CMD.command(:z4) do |event, *args|
    if event.channel.name != event.user.name
      @user = DB[:user][Digest::SHA2.hexdigest("#{event.user.id}")]
      @chan = DB[:chan][Digest::SHA2.hexdigest("#{event.channel.id}")]
      @users = event.message.mentions
      @roles = []
      event.message.role_mentions.each { |e| @roles << e.name }
      o = ["=^.^= CMD #{@user} #{@chan} #{@users} #{@roles}"]
      @@CB.each_pair { |k,v| if m = /#{k}/.match(event.content); o << v.call(event, args, m); end }
      #    if o.length > 1
      event.respond %[#{o.join("\n")}]
      #    end
    end
  end
  def self.start!
    Process.detach( fork { @@BOT.run } )
    Process.detach( fork { @@CMD.run } )
  end
  def self.stop!
    @@BOT.stop
    @@CMD.stop
  end
end

BOT.message("echo") do |ev, m|
  "ECHO #{ev} #{m}"
end
BOT.command("ping") do |ev, a, m|
  "PING #{ev} #{a} #{m}"
end
