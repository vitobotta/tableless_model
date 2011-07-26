$LOAD_PATH.unshift(File.dirname(__FILE__))

require "validatable"
require "active_record"
require "active_support"
require "activerecord/base/class_methods"
require "activerecord/base/instance_methods"
require "tableless_model/class_methods"
require "tableless_model/instance_methods"
require "tableless_model/version"


module ActiveRecord
  
  # TablelessModel class is basically an Hash with method-like keys that must be defined in advance
  # as for an ActiveRecord model, but without a table. Trying to set new keys not defined at class level
  # result in NoMethodError raised 

  class TablelessModel < Hash

    extend   Tableless::ClassMethods

    include  Tableless::InstanceMethods
    include  Validatable

 
    attr_accessor :__owner_object, :__serialized_attribute
    
    # 
    # 
    # Exposes an accessors that will store the names of the attributes defined for the Tableless model,
    # and their default values
    # This accessor is an instance of Set defined in the inheriting class (see self.inherited)
    # 
    # 
    class << self
      attr_reader :attributes
      
    end

  end
end

