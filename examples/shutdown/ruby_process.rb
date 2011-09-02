require 'rubygems'
require 'karait'

puts 'Starting Ruby process.'
queue = Karait::Queue.new

while true
  messages = queue.read :routing_key => 'ruby_process'
  
  if messages.first and messages.first.action == 'shutdown_routed'
    puts 'Terminating due to routed shutdown message.'
    messages.first.delete
    break
  end
  
  messages = queue.read
  if messages.first and messages.first.action == 'shutdown_broadcast'
    puts 'Terminating due to broadcast shutdown message.'
    break
  end

end
