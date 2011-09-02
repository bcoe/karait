require 'mongo'

module Karait
  class Queue
    
    include Karait
    
    MESSAGE_LIMIT = 10
    
    def initialize(opts={})
      set_instance_variables opts
      create_mongo_connection
    end
    
    def write(message, opts={})
      if message.class == Hash
        message_dict = message
      else
        message_dict = message.to_hash
      end
      
      message_dict[:_meta] = {
        :expire => opts.fetch(:expire, -1.0),
        :timestamp => Time.now().to_f,
        :expired => false
      }
      
      message_dict[:_meta][:routing_key] = opts.fetch(:routing_key) if opts[:routing_key]
      
      @queue_collection.insert(message_dict, :safe => true)
    end
    
    def read(opts={})
      messages = []
      
      conditions = {
          '_meta.expired' => false
      }
      
      if opts[:routing_key]
        conditions['_meta.routing_key'] = opts[:routing_key]
      else
        conditions['_meta.routing_key'] = {
          '$exists' => false
        }
      end
      
      @queue_collection.find(conditions).limit(opts.fetch(:message_limit, Queue::MESSAGE_LIMIT)).each do |raw_message|
        message = Karait::Message.new(raw_message=raw_message, queue_collection=@queue_collection)
        if message.expired?
          message.delete()
        else
          messages << message
        end
      end
      
      return messages
    end
    
    private
    
    def set_instance_variables(opts)
      
      defaults = {
        :host => 'localhost',
        :port => 27017,
        :database => 'karait',
        :queue => 'messages',
        :average_message_size => 8192,
        :queue_size => 4096
      }.merge(opts)
      
      @host = defaults[:host]
      @port = defaults[:port]
      @database = defaults[:database]
      @queue = defaults[:queue]
      @average_message_size = defaults[:average_message_size]
      @queue_size = defaults[:queue_size]
      
    end
    
    def create_mongo_connection
      @connection = Mongo::Connection.new(
        @host,
        @port
      )
      @database = @connection[@database]
      create_capped_collection
      @queue_collection = @database[@queue]
      @queue_collection.create_index('_meta.routing_key')
    end
    
    def create_capped_collection
      @database.create_collection(
        @queue,
        :size => (@average_message_size * @queue_size),
        :capped => true,
        :max => @queue_size
      )
    end
    
  end
end