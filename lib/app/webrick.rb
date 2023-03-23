module APP
  @@APP = WEBrick::HTTPServer.new :Port => 4567, :DocumentRoot => "#{Dir.pwd}/public/"
  @@APP.mount_proc '/' do |req, res|
    @app = App.new(req)
    if @app[:uri] == '/'
      params = @app.params
    res.body = ERB.new(@app.html).result(binding)
    elsif File.exist? "views#{@app[:uri]}.erb"
      params = @app.params
      res.body = ERB.new(File.read("views#{@app[:uri]}.erb")).result(binding)
    elsif File.exist? "public#{@app[:uri]}"
      res.body = File.read("public#{@app[:uri]}")
    end
  end
  @@APP.mount_proc '/manifest.webmanifest' do |req, res|
    res['Content-Type'] = 'application/javascript'
    res.body = ''
  end
  @@APP.mount_proc '/favicon.ico' do |req, res|
    res.body = ''
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
      @app = {
        head: 'head',
        body: 'body',
        img: '/bg.img',
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
    def params
      @params
    end
    def html
      b = [
        "<!DOCTYPE html><html><head>",
        @head,
        "</head><body>",
        "<img id='bg' src='#{@app[:img]}'>",
        "<form id='form' action='/' method=''>",
        @body,
        "</form></body></html>"
      ].flatten.join("")
      return ERB.new(b).result(binding)
    end
  end
end

