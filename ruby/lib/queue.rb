require 'mongo'

module Karait
  class Queue
    
    include Karait
    
    MESSAGES_READ = 10
    
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
        :visibility_timeout => -1.0,
        :accessed => 0.0
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
      
      get_raw_messages(
        conditions,
        opts.fetch(:messages_read, Queue::MESSAGES_READ),
        opts.fetch(:visibility_timeout, -1.0)
      ).each do |raw_message|
        message = Karait::Message.new(raw_message=raw_message, queue_collection=@queue_collection)
        messages << message
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
    
    def get_raw_messages(conditions, messages_read, visibility_timeout, should_retry=true)
      if @queue_collection.find(conditions).count() == 0
        return []
      end
      
      raw_messages = @database.eval(BSON::Code.new(
        "
        function() {
            if (typeof karait_queue_find === 'undefined') {
                return false;
            }
            return karait_queue_find(collection, conditions, limit, visibilityTimeout);
        }
        ",
        {
          'conditions' => conditions,
          'limit' => messages_read,
          'collection' => @queue,
          'visibilityTimeout' => visibility_timeout
        })
      )
      
      if raw_messages
        return raw_messages
      elsif should_retry
        generate_and_store_karait_queue_find_helper
        return get_raw_messages(conditions, messages_read, visibility_timeout, false)
      end
      return []
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
    end
    
    def create_capped_collection
      @database.create_collection(
        @queue,
        :size => (@average_message_size * @queue_size),
        :capped => true,
        :max => @queue_size
      )
    end
    
    def generate_and_store_karait_queue_find_helper
      karait_queue_find = BSON::Code.new(
        "
        function(collection, conditions, limit, visibilityTimeout) {
            var results = [];
            var currentTime = parseFloat(new Date().getTime()) / 1000.0;
            
            function hiddenByVisibilityTimeout(result) {
                if ( (currentTime - result._meta.accessed) < (result._meta.visibility_timeout) ) {
                    return true;
                }
                return false;
            }
            
            function expire(result) {
                if (result._meta.expire <= 0.0) {
                    return false;
                } else if ( (currentTime - result._meta.timestamp) > result._meta.expire ) {
                    db[collection].update({_id: result._id}, {$set: {'_meta.expired': true}})
                    return true;
                }
            }
            
            (function fetchResults() {
                var cursor = db[collection].find(conditions).limit(limit);
                var accessedIds = [];
                cursor.forEach(function(result) {
                    if (!expire(result) && !hiddenByVisibilityTimeout(result)) {
                        results.push(result);
                        accessedIds.push(result._id);
                    }
                });
                if (visibilityTimeout != -1.0) {
                    db[collection].update({_id: {$in: accessedIds}},
                        {
                            $set: {
                                '_meta.accessed': currentTime,
                                '_meta.visibility_timeout': visibilityTimeout
                            }
                        },
                        false,
                        true
                    );
                }
            })();
        
            return results;
        }
        "
      )
      @database['system.js'].save({:_id => 'karait_queue_find', :value => karait_queue_find})
    end
  end
end