module Base
  module ClassMethods

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
    #       has_tableless :settings
    # 
    #       # or...
    # 
    #       has_tableless :settings => ParentSettings
    # 
    #     end
    # 
    # 
    # NOTE: the serialized column is expected to be of type string or text in the database
    # 
    def has_tableless(column)
      column_name = column.class == Hash ? column.collect{|k,v| k}.first.to_sym : column
      
      # if only the column name is given, the tableless model's class is expected to have that name, classified, as class name
      class_type = column.class == Hash ? column.collect{|k,v| v}.last : column.to_s.classify.constantize


      # injecting in the parent object a getter and a setter for the
      # attribute that will store an instance of a tableless model
      class_eval do

        # Telling AR that the column has to store an instance of the given tableless model in 
        # YAML serialized format
        serialize column_name
    
        # Adding getter for the serialized column,
        # making sure it always returns an instance of the specified tableless
        # model and not just a normal hash or the value of the attribute in the database,
        # which is plain text
        define_method column_name.to_s do
          instance = class_type.new(read_attribute(column_name.to_sym) || {})
          
          instance.__owner_object         = self
          instance.__serialized_attribute = column_name
          
          instance
        end
    
        # Adding setter for the serialized column,
        # making sure it always stores in it an instance of 
        # the specified tableless model (as the argument may also be a regular hash)
        define_method "#{column_name.to_s}=" do |value|
          super class_type.new(value)
        end
      end
    end

  end
end


# Extending ActiveRecord::Base class with a macro required by the Tableless model,
# and another one that can be used to serialize a tableless model instance into
# a parent object's column

ActiveRecord::Base.extend Base::ClassMethods
