require 'rubygems'
require 'karait'
require 'yaml'

puts "Starting ruby reader."

messages_read = 0.0
start_time = Time.now().to_f

queue = Karait::Queue.new
while true
  messages = queue.read :routing_key => 'for_reader', :messages_read => 15, :visibility_timeout => 0.1
  messages.each do |message|
    messages_read += 1.0
        
    message.messages_read = messages_read
    message.messages_read_per_second = messages_read / (Time.now().to_f - start_time)
    
    puts "Message Read: \n#{message.to_hash.to_yaml}"
  end
  queue.delete_messages messages
end
