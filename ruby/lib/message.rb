module Karait
  class Message
    
    include Karait
    
    VARIABLE_REGEX = /^([a-z_][a-zA-Z_0-9]*)=$/
    BLACKLIST = {
        '_meta' => true,
        '_id' => true,
        '_expired' => true
    }
    
    def initialize(raw_message={}, queue_collection=nil)
      @source = raw_message
      @queue_collection = queue_collection
      @variables_to_serialize = {}
      add_accessors raw_message
    end
    
    def to_hash
      hash = {}
      @variables_to_serialize.keys.each do |k|
        hash[k] = self.send k
      end
      return hash
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
    
    private
    
    def add_accessors(hash)
      hash.each do |k, v|
        if not Message::BLACKLIST.has_key? k
          add_accessible_attribute k, v
          @variables_to_serialize[k.to_s] = true
        end
      end
    end
    
    def method_missing(id, *args)
      if matches = id.to_s.match(Message::VARIABLE_REGEX) and args.count == 1
        add_accessible_attribute(matches[1], args[0])
        @variables_to_serialize[matches[1]] = true
      else
        raise NoMethodError
      end
    end
    
  end
end