
require 'pry'

#require 'irb'
#require 'irb/completion'

load 'lib/app.rb'

['INT', 'TERM'].each { |e| trap(e)  { APP.stop!; BOT.stop!; } }

BROKER.start!
APP.start!
BOT.start!

Pry.config.prompt = Pry::Prompt.new(
  "z4",
  "the z4 prompt",
  [
    proc { |obj, nest_level, _| "#{obj}[#{nest_level}]> " },
    proc { |obj, nest_level, _| "#{obj}(#{nest_level})> " }
  ]
)
Pry.start(Z4)
#IRB.conf[:PROMPT_MODE] = :CLASSIC
#IRB.conf[:IRB_NAME] = "Z4"
#IRB.start
