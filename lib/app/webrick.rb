module APP
  def self.enc s
    ERB::Util.url_encode s
  end
  def self.dec s
    ERB::Util.url_decode s
  end
  
  def self.erb sym
    ERB.new(File.read("views/#{sym}.erb")).result(binding)
  end
  
  @@APP = WEBrick::HTTPServer.new :Port => 4567, :DocumentRoot => "#{Dir.pwd}/public/"
  @@APP.mount_proc '/' do |req, res|
    @app = App.new(req)
    puts "@app #{@app.params}"
    if @app[:uri] == '/'
      if !@app.params.has_key? 'qr'
        res.status = 200
        res.content_type = "text/html"
        params = @app.params
        res.body = ERB.new(@app.html).result(binding)
      else
        params = CORE[@app.params['qr']]
        res.status = 200
        res.content_type = "text/html"
        res.body = ERB.new(@app.scan).result(binding)
      end
    elsif File.exist? "views#{@app[:uri]}.erb"
      res.status = 200
      res.content_type = "text/html"
      params = @app.params
      html = [%[<!DOCTYPE html><html><head>],
              File.read("views/head.erb"),
              %[</head><body><form id='form'>],
              File.read("views#{@app[:uri]}.erb"),
              %[</form></body></html>]].join("")
      res.body = ERB.new(html).result(binding)
    elsif File.exist? "public#{@app[:uri]}"
      f = "public#{@app[:uri]}"
      {
        ".wasm" => 'application/wasm',
        ".png" => 'image/png',
        ".jpg" => 'image/jpg',
        ".jpeg" => 'image/jpeg',
        ".gif" => 'image/gif',
        ".js" => 'application/javascript'
      }.each_pair do |ext, mime|
        if /#{ext}$/.match(f)
          res.content_type = mime
        end
      end
      res.status = 200
      res.body = File.read("public#{@app[:uri]}")
    end
  end
  
  def self.app
    @@APP
  end
  def self.start!
    Process.detach(fork { @@APP.start })
  end
  def self.stop!
    @@APP.shutdown
  end
  class App
    def initialize req
      @req = req
      #puts "#{@req}"
      @params = @req.query
      @uri = @req.unparsed_uri.split('?')[0]
      @host = DB[:host][@req.host]
      @app = {
        head: @host[:head],
        body: @host[:body],
        img: @host[:img],
        uri: @uri,
        host: @req.host
      }
      [:head, :body].each { |e| if @params.has_key?(e.to_s); @app[e] = @params[e.to_s]; end }
      @head, @body = File.read("views/#{@app[:head]}.erb"), File.read("views/#{@app[:body]}.erb")
      puts "#{@app}"
    end
    def [] k
      @app[k]
    end
    def host
      @host
    end
    def params
      @params
    end

    def element str, h={}
      a = []
      el = h.delete(:el)
      bg = h.delete(:bg)
      fg = h.delete(:fg)
      bd = h.delete(:bd)
      str.split(' ').each do |word|
        if m = /(.+)?:(.+):(.+)?/.match(word)
          if m[1]
            cl = m[1]
          else
            el = 'white'
          end
          x = m[2]
          if m[3]
            st = m[3]
          else
            st= 'normal'
          end
          a << %[<span style='color: #{cl}; font-weight: bold; font-family: #{st};'>#{x}</span>]
        else
          a << word
        end
      end
      return %[<#{el || 'p'} style='width: 100%; text-align: center;'><span style='color: #{fg || 'white'}; background-color: #{bg || 'black'}; border: thin solid #{bd || 'black'}; border-radius: 50px; padding: 2%;'>#{a.join(' ')}</span></#{el || 'p'}>]
    end

    def collection h={}
      el = h.delete(:in)
      ea = h.delete(:el)
      bg = h.delete(:bg)
      fg = h.delete(:fg)
      bd = h.delete(:bd)
      a = [%[<#{el || 'div'}>]]
      h.each_pair do |k,v|
        a << element("#{k}", el: ea || 'span', bg: bg || 'black', fg: fg || 'white', bd: CORE.color(v.to_i) )
      end
      a << %[</#{el || 'div'}>]
      return a.join("")
    end
    
    def menu_icon icon, link
      s = [
        %[border-color: white;],
        %[text-decoration: none;],
        %[color: white;]
      ].join('')
      %[<a class='material-icons obj' href='#{link}' style='#{s}'>#{icon}</a>]
    end
    
    def menu t, i
      a, x = [], DB[t.to_sym][i]
      [:link, :share, :bookmark, :movie, :phone, :business].each do |key|
        if "#{x[key.to_sym]}".length > 0
          a << menu_icon(key, x[key.to_sym])
        end
      end
      return a
    end
    
    def scan
      qr = CORE[@params['qr']]
      vs = %[https://#{@app[:host]}/qr?user=#{qr['user']}&chan=#{qr['chan'] || @app[:host]}&visitor=#{CORE.now.to_i}]
      s, l, hd, bd, ft, mn, head, foot = {}, {}, [], [], [], [], [], []
      img = '/bg.img'
      ['chan', 'user'].each do |type|
        if qr.keys.include? type
          s[type] = DB[type.to_sym][qr[type]]
          l[type] = menu(type, qr[type])
        end
      end
      
      l[:app] = [menu_icon('qr_code', vs)]

      s.each_pair { |k,v| hd << File.read("views/scan/#{k}.erb") }

      if s.has_key?('user') && !s.has_key?('chan')
        if "#{s['user'][:brand]}".length > 0
          img = s['chan'][:img]
        end

        w = s['user'].weight[:roles].to_h
        if w.keys.length > 0
          head << collection({ in: 'h3' }.merge(w))
        end
        
        if "#{s['user'][:desc]}".length > 0
          el = element(s['user'][:desc])
          foot << %[<div style='width: 100%; text-align: center;'>#{el}</div>]
        end
      end
      
      if s.has_key? 'chan'
        if "#{s['chan'][:brand]}".length > 0
          img = s['chan'][:img]
        end
        if "#{s['chan'][:desc]}".length > 0
          el = element(s['chan'][:desc])
          head << %[<div style='width: 100%; text-align: center;'>#{el}</div>]
        end
        if "#{s['chan'][:item]}".length > 0
          el = element(s['chan'][:item])
          foot << %[<div style='width: 100%; text-align: center;'>#{el}</div>]
        end
      end
      
      l.each_pair { |k,v| ft << v }
      
      b = [
        "<!DOCTYPE html><html><head>",
        @head,
        "</head><body>",
        %[<img id='bg' src='#{img}'>],
        "<form id='form' action='/' method='get'>",
        %[<h1 class='head' style='width: 100%; text-align: left;'>],
        hd,
        %[</h1>],
        bd,
        head,
        %[<div class='foot' style='width: 100%; text-align: center;'>],
        foot,
        %[<h1 style='width: 100%; text-align: center; margin: 0;'>],
        ft,
        "</h1></div></form></body></html>"
      ].flatten.join("")
      return b
    end
    
    def html
      b = [
        "<!DOCTYPE html><html><head>",
        @head,
        "</head><body>",
        "<img id='bg' src='#{@app[:img]}'>",
        "<form id='form' action='/' method='get'>",
        @body,
        "</form></body></html>"
      ].flatten.join("")
      return b
    end
  end
end

