module BOT
  HELP = [
    %[A simple discord channel manager inspired by my cat.],
    %[MORE HELP: `#cat help`],
    %[HERE <place> => checkin at a place.]
  ]
  def self.erb str
    ERB.new(str).result(binding)
  end
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

      o = []

      @@MSG.each_pair { |k,v| if @m = /\A#{k}\z/.match(event.content); o << v.call(event, @m);  end }

      @user = DB[:user]["#{event.user.id}"]

      if @user.weight[:roles].keys.include? 'operator'
        o << %[:cat: https://#{@user[:host]}/cat?user=#{@user.for}]
      end
      
      stat = []
      [ :xp, :gp, :chans, :roles ].each do |e|
        stat << %[#{e}: #{@user[e]}]
      end
      o << %[stats: #{stat.join(", ")}]

      [ :name, :desc, :brand, :bookmark, :movie, :phone ].each do |k|
        o << %[#{k}: #{@user[k]}]
      end

      if "#{@user[:event]}".length > 0
        o << %[]
        o << %[event: #{@user[:event]}]
        x = DB[:event][@user[:event]]
        stat = []
        [].each do |e|
          stat << %[#{e}: #{x[e]}]
        end
        o << %[stats: #{stat.join(", ")}]

        [].each do |k|
          o << %[#{k}: #{x[k]}]
        end
      else
        o << %[event: no user event set.]
      end
      
      o << %[]

      o << %[:id: https://#{@user[:host]}#{QR['profile'].route(user: @user.for)}]

      # respond with private message.
      snd = []
      o.flatten.each { |e|
        if %[#{snd.join("\n")}].length + "#{e}".length < 2000;
          snd << e;
        else;
          event.user.pm(%[#{snd.join("\n")}]);
          snd = [ e ]
          sleep 1
        end
      }
      event.user.pm(%[#{snd.join("\n")}]);
    end
  end
  
  @@CMD = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], prefix: '#'
  @@CMD.command(:cat, { usage: %[#cat <cmd> [args]], description: HELP.join("\n") }) do |event, *args|
    if event.channel.name != event.user.name
      @om = []
      @pm = []
      @mm = [':MENTION:']

      # create channel object
      @chan = DB[:chan]["#{event.channel.id}"]
      if @chan[:name] == ''
        @chan.update name: event.channel.name
        @pm << %[##{@chan[:name]} created.]
        if DB[:chan].entries.length == 1
          @pm << %[##{@chan[:name]} is the server root channel.]
        end
      end
      
      # create user object
      @user = DB[:user]["#{event.user.id}"]
      if @user[:name] == ''
        @user.update name: event.user.name
        if DB[:user].entries.length == 1
          CORE.levels.each { |e| @user.weight[:roles].incr(e.to_s) }
          @user.update roles: @user.weight[:roles].keys.length
          @pm << %[You are now the server operator.]
        end
      end

      # predefine output arrays.
      if @chan[:verbose] == true
        @om << "Z4 CM #{CORE.now}"
        @pm << "Z4 PM #{CORE.now}"
        @mm << "Z4 MM #{CORE.now}"
        @pm << %[EVENT: #{event}]
      elsif @chan[:friendly] == true
        @om << "=^.^= Channel Message at #{CORE.now}"
        @pm << "=^.^= Private Message at #{CORE.now}"
        @mm << "=^.^= Mention Message at #{CORE.now}"
      end
      
      # find users.
      users = []
      event.message.mentions.each {|e| users << "#{e.id}" }

      # find roles.
      roles = []
      event.message.role_mentions.each { |e| roles << e.name }

      # shift command from message.
      args.shift

      # remove mentions and #z4
      m = event.content.split(' ')
      m.delete_if { |e| /@.+/.match(e) }
      m.shift()

      # attachments (NOT working)
      images = []
      if event.message.attachments.length > 0
        event.message.attachments {|e| if e.image?; images << e.url; end }
      end

      # emoji actions (NOT working)
      emoji = []
      if event.message.emoji.length > 0
        event.message.emoji {|e| emoji << e.id }
      end

      # generate command object
      ev = {
        user: "#{event.user.id}",
        chan: "#{event.channel.id}",
        users: users,
        roles: roles,
        content: m.join(' '),
        args: args,
        emoji: emoji,
        images: images
      }
        
      # match handler.
      @@CB.each_pair { |k,v|
        if @m = /\A#{k}\z/.match(event.content);
          h = v.call(event, ev, @m);
          @om << h[:out]
          @pm << h[:pm]
          @mm << h[:to]
        end
      }

      # respond with channel message.
      if @om.flatten.length > 0;
        snd = [];
        @om.flatten.each {|e|
          if %[#{snd.join("\n")}].length + "#{e}".length < 2000;
            snd << e;
          else;
            event.respond(%[#{snd.join("\n")}]);
            snd = [ e ]
            sleep 1
          end
        }
        event.respond(%[#{snd.join("\n")}]);
      end

      # respond with private message.
      if @pm.flatten.length > 0;
        snd = []
        @pm.flatten.each { |e|
          if %[#{snd.join("\n")}].length + "#{e}".length < 2000;
            snd << e;
          else;
            event.user.pm(%[#{snd.join("\n")}]);
            snd = [ e ]
            sleep 1
          end
        }
        event.user.pm(%[#{snd.join("\n")}]);
      end

      # handle messages to mentioned users.
      if @mm.length > 1;
        event.message.mentions.each {|e| e.pm(%[#{@mm.join("\n")}]) };
      end

      return nil
      
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

BOT.message("SET (.+) (.*)") do |ev, m|
  user = DB[:user]["#{ev.user.id}"]
  user.update m[k].to_sym => m[2]
  %[SET => USER[#{k}] = #{v}]
end

BOT.message("RUN (.+)(.*)?") do |ev, m|
  k = m[1]
  v = m[2].split(' ')
  user = DB[:user]["#{ev.user.id}"]
  r = "result..."
  # do source run
  %[RUN (#{k}, #{v}) => #{r}]
end

BOT.command("(.*)?") do |ev, h, m|
  @om, @pm, @mm, @cmds, @tgr = [], [], [], {}, false

  mm = m[1].split(' ')
  mm.shift
  
  user = DB[:user][h[:user]]
  chan = DB[:chan][h[:chan]]
  
  LOGIC.chan h[:chan], h[:user]

  user.update host: chan[:host]
  
  if chan[:verbose] == true
    @pm << "#Z4 #{user.for} #{chan.for} #{h} #{mm}"
  end

  if mm[0] == 'help' || mm[0] == 'usage' || mm[0] == '-h' || mm[0] == '-u'
    rom, rpm, @tgr = [], [], true
    rpm << %[BOT COMMANDS:]
    rpm << %[The bot will let you interact with your profile data.  It understands two commands.]
    rpm << %[]
    rpm << %[INFO => display profile info.]
    rpm << %[SET <key> <value> => update profile settings.]
    rpm << %[RUN <function> [args] => run the local event source with arguments.]
    rpm << %[]
    rpm << %[CHANNEL COMMANDS:]
    rpm << %[In a channel, commands are only accessible by server and channel roles.]
    rpm << %[As you gain more roles, you will have more access.]
    rpm << %[]
    rpm << %[usage: (write) `#cat <command> [*args] || <place>`]
    rpm << %[usage:  (read) `#cat`]
    rpm << %[]
    rpm << %[@operator: for the running of the team.]
    rpm << %[set <key> <value> => force team settings.]
    rpm << %[mount <device> => attach iot device]
    rpm << %[]
    rpm << %[@agent: for the configuration of items.]
    rpm << %[SET <key> <value> => set team settings.]
    rpm << %[ITEM <key> <value> => set the current item's settings.]
    rpm << %[JOB <item> => change the current team job.]
    rpm << %[PAY => pay team members for their work on the current job.]
    rpm << %[]
    rpm << %[@ambassador: for the coordination of places.]
    rpm << %[HERE [place] => set channel place if provided get qr scanner.]
    rpm << %[]
    rpm << %[@influencer: available for the coordination of events.]
    rpm << %[DO <event> => begin an influencer event.]
    rpm << %[EVENT <key> <value> => set configuration for current event.]

    rom << %[usage: #cat <command> [args] || <place>]
    @pm << [%[MANUAL], rpm, %[] ]
    @om << [%[USAGE], rom, %[]]
  end
  
  if user.weight[:roles].keys.include? 'operator'
    @cmds['operator'] = ['set', 'host', 'cat']
    rom, rpm = [], []
    
    if ev.message.mentions.length > 0 && ev.message.role_mentions.length > 0
      ev.message.role_mentions.each { |role|
        ev.message.mentions.each { |u|
          uu = DB[:user]["#{u}"]
          ch = DB[:chan]["#{h[:chan]}"]
          ro = DB[:ro]["#{role.name}"]
          ro.weight[:chans].incr(ch.for)
          ro.update chans: ro.weight[:chans].keys.length
          ro.weight[:users].incr(uu.for)
          ro.update users: ro.weight[:users].keys.length
          LOGIC.role ch.for, ro.for, uu.for
          @pm << %[#{ch.for} (#{ro.for}) => #{uu.for}]
        }
      }
      @mm << %[Z4 UPDATE #{h[:roles]} => #{h[:users]}]
      @mm << %[Z4 JOB #{h[:content]}]
    elsif ev.message.mentions.length > 0 && ev.message.role_mentions.length == 0
      @mm << %[you were mentioned in #{chan[:name]}]
    elsif ev.message.mentions.length == 0 && ev.message.role_mentions.length > 0
      @pm << %[##{chan[:name]} (#{h[:roles]})]
#    else
#      @pm << %[no roles or users acted on.]
    end
    
    if mm[0] == "set"
      @tgr = true
      mm.shift
      k = mm[0]
      mm.shift
      v = mm.join(' ')
      if v == 'true'
        vv = true
      elsif v == 'false'
        vv = false
      else
        vv = v
      end
      chan.update({ k.to_sym => vv })
      rom << %[CHAN[#{k}] = #{vv}]
      rpm << %[##{chan[:name]} CHAN[#{k}] = #{vv}]
    elsif mm[0] == 'mount'
      @tgr = true
      mm.shift
      v = mm.join(' ')
      rom << %[CHAN[:decive] = #{v}]
      rpm << %[]
    elsif mm[0] == "host"
      @tgr = true
      mm.shift
      k = mm[0]
      mm.shift
      v = mm.join(' ')
      DB[:host][chan[:domain]].update({ k.to_sym => v })
      rom << %[#{chan[:host]}[#{k}] = #{v}]
      rpm << %[##{chan[:name]} #{chan[:host]}[#{k}] = #{v}]
    end
   
    if chan[:verbose] == true
      @om << [ %[OPERATOR: #{@cmds['operator']}], rom, %[] ]
      @pm << [ %[:OPERATOR:], rpm, %[] ]
    else
      @pm << rpm
      @om << rom
    end
    
  end

  if user.weight[:roles].keys.include? 'agent'
    @cmds['agent'] = ['PAY', 'JOB', 'ITEM', 'SET']
    rom, rpm = [], []
    if mm[0] == 'PAY'
      @tgr = true
      LOGIC.pay h[:chan], h[:users]
      rpm << %[##{chan[:name]} paid #{h[:users].length} users for '#{chan[:item]}' job.]
      rom << %[#{user[:name]} paid ##{chan[:name]} for '#{chan[:item]}' job.]
    elsif mm[0] == 'JOB'
      @tgr = true
      mm.shift
      chan.update item: mm.join(' ')
      i = "#{chan.for}-#{chan[:item]}"
      item = ITEM[i]
      rom << %[CHAN[item] = #{mm.join(' ')}]
      rpm << %[##{chan[:name]} ITEM = #{chan[:item]}]
    elsif mm[0] == "ITEM"
      @tgr = true
      i = "#{chan.for}-#{chan[:item]}"
      item = ITEM[i]
      mm.shift
      k = mm[0]
      mm.shift
      v = mm.join(' ')
      item.update({ k.to_sym => v })
      rom << %[ITEM[#{chan[:item]}][#{k}] = #{v}]
      rpm << %[##{chan[:name]} ITEM[#{chan[:item]}][#{k}] = #{v}]
    elsif mm[0] == 'SET'
      @tgr = true
      if chan[m[1].to_sym].class == String && m[2].class == String
        mm.shift
        k = mm[0]
        mm.shift
        v = mm.join(' ')
        chan.update({ k.to_sym => v })
        rom << %[CHAN[#{k}] = #{v}]
        rpm << %[##{chan[:name]} CHAN[#{k}] = #{v}]
      end
    elsif mm[0] == 'HAS'
      @tgr = true
      has = []
      mm.shift
      if mm.length > 0
        k = mm[0].to_sym
        mm.shift
        has << %[ #{k} HAS]
        if mm.length > 0
          v0 = mm[0].to_sym
          mm.shift
          has << %[ filter: #{v0} =>]
          if mm.length > 0
            v1 = mm[0]
            x = DB.filter(k, v0 => v1 )
            has << %[ by #{v1} => #{x.length}]
            rpm << %[:search: https://#{chan[:host]}/q?table=#{k}&#{v0}=#{v1}]
          else
            ft = Hash.new { |h,k| h[k] = 0 }
            DB.filter(k).each do |e|
              e[v0].each {|ee| ft[ee] += 1 }
            end
            has << %[ attributes: #{ft.keys.join(", ")}]
          end
        else
          a = []
          x = DB.filter(k)[0].to_h.each_pair { |k,v| if v.class == Array; a << k; end }
          has << %[ keys: #{a.join(", ")}]
        end
      else
        has << %[ tables: #{DB.dbs.join(", ")}]
      end
      rpm << %[##{chan[:name]} #{has.join(" ")}]
    end
    
    if chan[:verbose] == true
      @om << [ %[AGENT: #{@cmds['agent']}], rom, %[] ]
      @pm << [ %[:AGENT:], rpm, %[] ]
    else
      @pm << rpm
      @om << rom
    end
  end
  
  if user.weight[:roles].keys.include? 'ambassador'
    @cmds['ambassador'] = ['HERE']
    rom, rpm = [], []
    if mm[0] == 'HERE'
      @tgr = true
      mm.shift
      if mm.length > 0
        v = mm.join(' ')
        chan.update place: v
        db = HERE[v]
        db.weight[:chans].incr(h[:chan])
        db.update(chans: db.weight[:chans].keys.length)
        rom << %[HERE = #{v}]
        rpm << %[##{chan[:name]} HERE = #{v}]
      end
      rpm << %[:eye: https://#{chan[:host]}/scanner?user=#{user.for}&chan=#{chan.for}]
    end
    
    if chan[:verbose] == true
      @om << [ %[AMBASSADOR: #{@cmds['ambassador']}], rom, %[] ]
      @pm << [ %[:AMBASSADOR:], rpm, %[] ]
    else
      @pm << rpm
      @om << rom
    end
  end

  if user.weight[:roles].keys.include? 'influencer'
    @cmds['influencer'] = ['DO', 'EVENT']
    rom, rpm = [], []

    if mm[0] == 'DO'
      @tgr = true
      mm.shift
      v = mm.join(' ')
      k = "#{h[:chan]}-#{v}-#{h[:user]}"
      db = DB[:event][k]
      user[:event] = k
      rom << %[CHAN[event] = #{v}]
      rpm << %[##{chan[:name]} CHAN[#{h[:user]}][:event] = #{v}]
    elsif mm[0] == 'EVENT'
      @tgr = true
      mm.shift
      k = mm[0]
      mm.shift
      v = mm.join(' ')
      db = DB[:event][user[:event]]
      db.update k.to_sym => v
      rom << %[EVENT[#{k}] = #{v}]
      rpm << %[##{chan[:name]} CHAN[h[:user]][:event] = #{db.to_h}]
    end
    
    if chan[:verbose] == true
      @om << [ %[INFLUENCER: #{@cmds['influencer']}], rom, %[] ]
      @pm << [ %[:INFLUENCER:], rpm, %[] ]
    else
      @pm << rpm
      @om << rom
    end
  end
  
  if mm.length == 0 && @tgr == false
    rpm << %[*#{chan[:name]}*]
    stat = []
    [ :xp, :gp, :roles, :pay ].each do |e|
      stat << %[#{e}: #{chan[e]}]
    end
    rpm << %[stats: #{stat.join(", ")}]

    [ :name, :host, :brand, :business, :link, :item, :place ].each do |k|
      rpm << %[#{k}: #{chan[k]}]
    end

    rpm << %[]

    if "#{chan[:item]}".length > 0
      rpm << %[SET item: #{chan[:item]}]
      item = DB[:item][chan[:item]]
      stat = []
      [].each do |e|
        stat << %[#{e}: #{item[e]}]
      end
      rpm << %[stats: #{stat.join(", ")}]

      [].each do |k|
        rpm << %[#{k}: #{item[k]}]
      end
    else
      rpm << %[SET item: no channel item set.]
    end

    rpm << %[]
    
    if "#{chan[:place]}".length > 0
      rpm << %[HERE: #{chan[:place]}]
      item = DB[:place][chan[:place]]
      stat = []
      [].each do |e|
        stat << %[#{e}: #{place[e]}]
      end
      rpm << %[stats: #{stat.join(", ")}]

      [].each do |k|
        rpm << %[#{k}: #{place[k]}]
      end
    else
      rpm << %[HERE: no channel place set.]
    end

    rpm << %[]
    
    rpm << %[COMMANDS:]
    @cmds.each_pair {|k,v| rpm << %[#{k}: #{v.join(", ")}] }

    rpm << %[]
    rpm << %[:identification_card: https://#{chan[:host]}#{QR[chan[:item]].route(chan: chan.for, user: user.for)}]
    
  elsif @tgr == false
    mm.shift
    user.update( here: mm.join(" ") )
    rpm << %[You are now at #{DB[:user][user.for][:here]}]
  end
  
  if chan[:verbose] == true
    @pm << %[:VERBOSE:]
    [%[CHAN #{chan.to_h}], %[], %[USER #{user.to_h}], %[], %[ITEM #{item.to_h}]].each { |e| @pm << e }
    @pm << %[:END:]
  end
  
  { out: @om, pm: @pm, to: @mm }
end

