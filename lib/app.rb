require 'webrick'
require 'erb'
require 'json'
require 'pstore'
require 'paho-mqtt'
require 'discordrb'

module Z4
  load 'lib/app/core.rb'
  load 'lib/app/db.rb'
  load 'lib/app/webrick.rb'
  load 'lib/app/bot.rb'
  load 'lib/app/broker.rb'
  load 'lib/app/logic.rb'
  load 'lib/app/places.rb'
  load 'lib/app/priv.rb'
  load 'lib/app/items.rb'
  load 'lib/app/streets.rb'
  load 'lib/app/intersections.rb'
  if File.exist? 'city.rb'
    load 'city.rb'
  end
end
