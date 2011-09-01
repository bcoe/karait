module Karait
  class Message
    
    include Karait
    
    VARIABLE_REGEX = /^([a-z_][a-zA-Z_0-9]*)=$/
    
    def initialize(raw_message={})
      @variables_to_serialize = {}
      add_accessors raw_message
    end
        
    private
    
    def add_accessors(hash)
      hash.each do |k, v|
        add_accessible_attribute k, v
        @variables_to_serialize[k] = true
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