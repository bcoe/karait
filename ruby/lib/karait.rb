require 'message'
require 'queue'

module Karait
  def add_accessible_attribute(k, v)
    @metaclass = metaclass = class << self; self; end unless @metaclass
    @metaclass.send :attr_accessor, k
    self.send "#{k}=", v
  end
end