class ActiveRecord::Base
  # 
  #  
  # delegates method calls for unknown methods to the tableless model
  # 
  def method_missing method, *args, &block
    if self.class.tableless_models
      self.class.tableless_models.each do |column_name| 
        serialized_attribute = send(column_name)
        return serialized_attribute.send(method, *args, &block) if serialized_attribute.respond_to?(method) 
      end
    end
    
    super method, *args, &block
  end
end

