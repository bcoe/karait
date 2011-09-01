require 'rubygems'
require 'karait'

puts 'Starting ruby writer.'

messages_written = 0
start = Time.new.to_f
queue = Karait::Queue.new

while true
    queue.write({
        'messages_written' => messages_written,
        'sender' => 'writer.rb',
        'started_running' => start,
        'messages_written_per_second' => (messages_written / (Time.new.to_f - start))
    }, :routing_key => 'for_reader')
    messages_written += 1
end