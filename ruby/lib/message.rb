module Karait
  class Message
    
    include Karait
    
    ASSIGN_VARIABLE_REGEX = /^([a-z_][a-zA-Z_0-9]*)=$/
    VARIABLE_REGEX = /^([a-z_][a-zA-Z_0-9]*)$/
    BLACKLIST = {
        '_meta' => true,
        '_id' => true,
        '_expired' => true
    }
    
    def initialize(raw_message={}, queue_collection=nil)
      @source = raw_message
      @queue_collection = queue_collection
      @variables_to_serialize = {}
      set_expired
      add_accessors raw_message
    end
    
    def to_hash
      return @variables_to_serialize
    end
    
    def delete
      @queue_collection.update(
          {
              '_id' => @source['_id']
          },
          {
              '$set' => {
                  '_meta.expired' => true
              }
          }
      )
    end
    
    def expired?
      return @expired
    end
    
    def get(key)
      return @variables_to_serialize[key.to_s]
    end
    
    def _get_id
      return @source['_id']
    end
    
    private
    
    def set_expired
      @expired = false
      
      current_time = Time.now().to_f
      meta = @source.fetch('_meta', {})
      
      return if meta.fetch('expire', -1.0) == -1.0
      
      if current_time - meta.fetch('timestamp', 0.0) > meta.fetch('expire', -1.0):
        @expired = true
      end
    end
    
    def add_accessors(hash)
      hash.each do |k, v|
        if not Message::BLACKLIST.has_key? k
          @variables_to_serialize[k.to_s] = v
        end
      end
    end
    
    def method_missing(sym, *args, &block)
      if matches = sym.to_s.match(Message::ASSIGN_VARIABLE_REGEX) and args.count == 1
        @variables_to_serialize[matches[1]] = args[0]
      elsif matches = sym.to_s.match(Message::VARIABLE_REGEX) and args.count == 0
        return @variables_to_serialize[matches[1]]
      else
        super(sym, *args, &block)
      end
    end
    
  end
end