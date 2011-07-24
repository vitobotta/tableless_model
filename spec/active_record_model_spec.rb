require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.connection.execute(" create table test_models (options varchar(50)) ")

class ModelOptions < ActiveRecord::TablelessModel
  attribute :no_default_value_no_type_attribute
  attribute :no_default_value_typed_attribute, :type => :integer 
  attribute :no_type_attribute, :default => 111
  attribute :typed_attribute,   :default => 5, :type => :integer 
  attribute :typed_attribute_no_default_value,  :type => :integer 
end

class TestModel < ActiveRecord::Base
  has_tableless :options => ModelOptions
end

describe TestModel do
  let(:test_model)  { subject }
  let(:options)     { test_model.options }  

  describe "#options" do
    it "is an instance of the tableless model" do
      options.should be_instance_of ModelOptions
    end
    
    it "honours the type of the attribute, when specified" do
      options.typed_attribute.should == 5
    end

    it "assumes the default type of an attribute is :string, if no type has been specified" do
      options.no_type_attribute.should == "111"
    end
    
    it "assigns a non-nil string value to an attribute with no type nor default value" do
      options.no_default_value_no_type_attribute.should == ""
    end
  
    it "assigns a non-nil value of the expected type to an attribute with type but no default value" do
      options.no_default_value_typed_attribute.should == 0
    end
    
    it "allows setting the value of a known attribute" do
      expect {
        options.typed_attribute = 1234
      }.to_not raise_error
    end
    
    it "doesn't recognise undefined attributes" do
      expect {
        options.unknown_attribute
      }.to raise_error NoMethodError
    end
    
    it "doesn't allow setting undefined attributes" do
      expect {
        options.unknown_attribute = "whatever"
      }.to raise_error NoMethodError
    end    
    
    it "does not allow merging, since the tableless mode is supposed to be used like a normal model, not a hash" do
      expect { 
        options.merge(:some_new_attribute => "whatever") 
      }.should raise_error NoMethodError
    end
    
    it "shows the expected object-like output on inspect" do
      options.inspect.should == "<#ModelOptions typed_attribute_no_default_value=0 no_default_value_no_type_attribute=\"\" no_default_value_typed_attribute=0 no_type_attribute=\"111\" typed_attribute=5>"
    end
    
    it "tries to enforce type casting if a type has been specified for an attribute" do
      test_values = [ "test", 1234, true, "1234.12", "2011-01-02 15:23" ]
      
      [ :string, :integer, :float, :decimal, :time, :date, :datetime, :boolean ].each do |type|
  
        # temporarily changing type
        ModelOptions.attributes[:typed_attribute_no_default_value][:type] = type
  
        instance = ModelOptions.new
        
        type_name = case type
        when :datetime then :date_time
        when :decimal then :big_decimal
        else type
        end
          
          
        # excluding some test values that would always fail depending on the type
        exclude_test_values = case type
        when :decimal then [ "test", true ]
        when :time then [ "test", 1234, true ]
        when :date then [ "test", 1234, true, "1234.12" ]
        when :datetime then [ "test", 1234, true ]
        else []
        end
          
        (test_values - exclude_test_values).each do |value|
          instance.typed_attribute_no_default_value = value
          
          if type == :boolean
            [true, false].include?(instance.typed_attribute_no_default_value).should == true
          else
            instance.typed_attribute_no_default_value.should be_kind_of type_name.to_s.classify.constantize
          end
        end
  
      end
    end
  end

end

# describe "An ActiveRecord::Base model" do
  # before do
    # class ModelOptions < ActiveRecord::TablelessModel
    #   attribute :aaa, :default => 111
    #   attribute :bbb, :default => "bbb"
    # end
    # 
    # ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
    # ActiveRecord::Base.connection.execute(" create table test_models (options varchar(50)) ")
    # 
    # class TestModel < ActiveRecord::Base
    #   has_tableless :options => ModelOptions
    # end
  # end

  
  
  # describe "instance" do
  #   before do
  #     @instance = TestModel.new
  #   end
  #   
  #   it "must respond to changed?" do
  #     @instance.must_respond_to "changed?"
  #     @instance.changed?.must_equal false
  #     @instance.changes.must_equal({})
  #   end
  #   
  #   it "sets the accessor __owner_object to self in the tableless model instance" do
  #     @instance.options.__owner_object.must_equal @instance
  #   end
  #   
  #   it "sets the accessor __serialized_attribute to the name of its column that stored the tableless model instance, serialized" do
  #     @instance.options.__serialized_attribute.must_equal :options
  #   end
  #   
  #   

  # 
  #   describe "setter" do
  #     before do
  #       @return_value = @instance.send("options=", { :aaa => "CCC", :bbb => "DDD"  })
  #     end
  # 
  #     it "correctly sets the serialized column" do
  #       @return_value.must_be_kind_of ModelOptions
  #       %w(aaa bbb).each{|m| @return_value.must_respond_to m}
  #       @instance.options.aaa.must_equal "CCC"
  #       @instance.options.bbb.must_equal "DDD"
  #     end
  #     
  #     it "forces the owner object to a changed state with partial_updates on" do
  #       @instance.options.aaa = "changed aaa"
  #       @instance.options.bbb = "changed bbb"
  # 
  #       @instance.options.aaa.must_equal "changed aaa"
  #       @instance.changes.keys.include?("options").must_equal true
  # 
  #       @instance.changes[:options][0].must_equal nil
  #       @instance.changes[:options][1].must_equal({"aaa"=>"changed aaa", "bbb"=>"changed bbb"})
  #     end
  # 
  #     it "should save the serialized column correctly" do
  #       @instance.save!
  #     
  #       instance = TestModel.first
  #       
  #       instance.options.aaa.must_equal "CCC"
  #       instance.options.bbb.must_equal "DDD"
  #       
  #        # Ensuring the serialize macro is used
  #       instance.options.must_be_kind_of ModelOptions
  #     end
  #   end
  # end
# end

  
