require 'rubygems'
require 'karait'
require 'yaml'

puts "Starting ruby reader/writer"

messages_read = 0.0
start_time = Time.now().to_f

queue = Karait::Queue.new
while true
  messages = queue.read :routing_key => 'for_ruby_reader_writer', :messages_read => 15
  messages.each do |message|
    messages_read += 1.0
    
    if (messages_read % 250) == 0.0
      puts "Message Read: \n#{message.to_hash.to_yaml}"
    end
    
    message.messages_read = messages_read
    message.messages_read_per_second = messages_read / (Time.now().to_f - start_time)
    queue.write message
  end
  queue.delete_messages messages
end
