require 'mongo'

module Karait
  class Queue
    
    include Karait
    
    MESSAGES_READ = 10
    NO_OBJECT_FOUND_ERROR = 'No matching object found'
    
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
        :expired => false,
        :visible_after => -1.0
      }
      
      message_dict[:_meta][:routing_key] = opts.fetch(:routing_key) if opts[:routing_key]
      
      @queue_collection.insert(message_dict, :safe => true)
    end
    
    def read(opts={})
      opts = {
        :messages_read => 10,
        :visibility_timeout => -1.0,
        :routing_key => nil,
        :block => false,
        :polling_interval => 1,
        :polling_timeout => nil
      }.update(opts)
      
      current_time = Time.new.to_f
      messages = []
      
      query = {
          '_meta.expired' => false,
          '_meta.visible_after' => {
            '$lt' => current_time
          }
      }
      if opts[:routing_key] != nil
        query['_meta.routing_key'] = opts[:routing_key]
      else
        query['_meta.routing_key'] = {
          '$exists' => false
        }
      end
      
      update = false
      if opts[:visibility_timeout] > -1.0
        update = {
            '$set' => {
              '_meta.visible_after' => current_time + opts[:visibility_timeout]
            }
        }
      end
      
      raw_messages = []
      
      # if we want to block, loop and sleep until messages are available (or we time out)
      if opts[:block]
        block_until_message_available( query, opts[:polling_interval], opts[:polling_timeout] )
      end

      if update
        (0..opts[:messages_read]).each do
          begin
            
            raw_message = @queue_collection.find_and_modify(:query => query, :update => update)
            
            if raw_message
              raw_messages << raw_message
            else
              break
            end
          
          rescue Mongo::OperationFailure => operation_failure
            if not  operation_failure.to_s.match(Queue::NO_OBJECT_FOUND_ERROR)
              raise operation_failure
            end
          end
          
        end
      else
        @queue_collection.find(query).limit(opts[:messages_read]).each do |raw_message|
          raw_messages << raw_message
        end
      end
      
      raw_messages.each do |raw_message|
        message = Karait::Message.new(raw_message=raw_message, queue_collection=@queue_collection)
        if not message.expired?
          messages << message
        end
      end
      
      return messages
    end
    
    def delete_messages(messages)
      ids = []
      messages.each {|message| ids << message._get_id}
      @queue_collection.update(
          {
              '_id' => {
                '$in' => ids
              }
          },
          {
              '$set' => {
                  '_meta.expired' => true
              }
          },
          :multi => true,
          :safe => true
      )
    end
    
    private
    
    def block_until_message_available(query, polling_interval=1.0, polling_timeout=None)
        current_time = Time.new.to_f
        
        while @queue_collection.find(query).count() == 0
            if polling_timeout and (Time.new.to_f - current_time) > polling_timeout
                break
            end
            
            sleep polling_interval
        end
    end
    
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
      @queue_collection.create_index('_id')
      @queue_collection.create_index('_meta.routing_key')
      @queue_collection.create_index('_meta.expired')
      @queue_collection.create_index('_meta.visible_after')
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
