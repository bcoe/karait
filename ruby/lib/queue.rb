require 'mongo'

module Karait
  class Queue
    
    include Karait
    
    def initialize(opts={})
      set_instance_variables opts
      create_mongo_connection
    end
    
    def write(message, routing_key=nil, expire=-1.0)
      if message.type == Hash
        message_dict = message
      else
        message_dict = message.to_hash
      end
      
      message_dict[:_meta] = {
        :expire => expire,
        :timestamp => Time.now().to_f,
        :expired => false
      }
      
      @queue_collection.insert(message_dict, :safe => true)
    end
    
    def read(routing_key=nil, message_limit=10)
      messages = []
      
      conditions = {
          '_meta.expired' => false
      }
      
      if routing_key
        conditions['_meta.routing_key'] = routing_key
      else
        conditions['_meta.routing_key'] = {
          '$exists' => false
        }
      end
      
      @queue_collection.find(conditions).limit(message_limit).each do |raw_message|
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
            
      defaults.each do |k,v|
        add_accessible_attribute(k, v)
      end
      
    end
    
    def create_mongo_connection
      @connection = Mongo::Connection.new(
        self.host,
        self.port
      )
      @database = @connection[self.database]
      create_capped_collection
      @queue_collection = @database[self.queue]
      @queue_collection.create_index('_meta.routing_key')
    end
    
    def create_capped_collection
      @database.create_collection(
        self.queue,
        :size => (self.average_message_size * self.queue_size),
        :capped => true,
        :max => self.queue_size
      )
    end
    
  end
end