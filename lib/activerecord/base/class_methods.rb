module Base
  module ClassMethods

    attr_reader :tableless_models
    
    
    # 
    # 
    # Macro to attach a tableless model to a parent, table-based model.
    # The parent model is expected to own a property/column having as name the first argument
    # (or the key if the argument is a hash )
    # 
    # Can be used this way:
    # 
    #     class Parent < ActiveRecord::Base
    #     
    #       has_tableless :settings => ParentSettings
    # 
    #       # or...
    # 
    #       has_tableless :settings => ParentSettings, :encryption_key => "secret"
    # 
    #     end
    # 
    # 
    # NOTE: the serialized column is expected to be of type string or text in the database
    def has_tableless(column)
      encryption_key = column.delete(:encryption_key)
      
      column_name, class_type = column.to_a.flatten

      @tableless_models ||= []
      @tableless_models << column_name
      
      
      # injecting in the parent object a getter and a setter for the
      # attribute that will store an instance of a tableless model
      class_eval do

        # Telling AR that the column has to store an instance of the given tableless model in 
        # YAML serialized format; if encryption is enabled, then serialisation/deserialisation will
        # be handled when encrypting/decrypting, rather than automatically by ActiveRecord,
        # otherwise the different object id would cause a different serialisation string each time
        
        serialize column_name unless encryption_key
    
        # Adding getter for the serialized column,
        # making sure it always returns an instance of the specified tableless
        # model and not just a normal hash or the value of the attribute in the database,
        # which is plain text
        define_method column_name.to_s do
          serialised = read_attribute(column_name) 
          
          value = if encryption_key
            serialised ? YAML::load(ActiveSupport::MessageEncryptor.new(encryption_key).decrypt(serialised)) : serialised
          else
            serialised || {}
          end

          instance   = class_type.new(value)
          
          instance.__owner_object         = self
          instance.__serialized_attribute = column_name
          
          instance
        end
    
        # Adding setter for the serialized column,
        # making sure it always stores in it an instance of 
        # the specified tableless model (as the argument may also be a regular hash)
        define_method "#{column_name.to_s}=" do |value|
          v = class_type.new(value)
          v = encryption_key ? ActiveSupport::MessageEncryptor.new(encryption_key).encrypt(YAML::dump(v)) : v
          super v
        end
        
      end
    end

  end
end


# Extending ActiveRecord::Base class with a macro required by the Tableless model,
# and another one that can be used to serialize a tableless model instance into
# a parent object's column

ActiveRecord::Base.extend Base::ClassMethods
