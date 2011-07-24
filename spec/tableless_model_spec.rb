require "spec_helper"

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
  let(:test_values) do
    {
      :no_default_value_no_type_attribute => "no_default_value_no_type_attribute",
      :no_default_value_typed_attribute   => 4567,
      :no_type_attribute                  => "no_type_attribute",
      :typed_attribute                    => 8765,
      :typed_attribute_no_default_value   => 34
    }
  end
  
  it "is not in a changed state if no properties have changed" do
    test_model.changed?.should == false
    test_model.changes.should == {}
  end
  
  context "when setting all (or more than one of) the tableless model's attributes at once" do
    before(:each) do
      test_model.options = test_values
    end
    
    it "the attributes have the expected values" do
      test_model.options.no_default_value_no_type_attribute.should == "no_default_value_no_type_attribute"
      test_model.options.no_default_value_typed_attribute.should == 4567
      test_model.options.no_type_attribute.should == "no_type_attribute"
      test_model.options.typed_attribute.should == 8765
      test_model.options.typed_attribute_no_default_value.should == 34
    end
    
    it "forces the owner model to a changed state with partial_updates on" do
      test_model.changed?.should == true
      test_model.changes.keys.should include "options"
      test_model.changes[:options][0].should be_nil
      test_model.changes[:options][1].should == test_values
    end
    
    context "and saving the parent model" do
      before(:each) do
        test_model.save!
      end
      
      it "correctly initialises the attributes with their expected values when reading from database" do
        # Not sure if these are really needed, but I am leaving them just in case Identity Map
        # prevents the record from being actually loaded from the database for this test.
        options    = nil
        test_model = nil
        
        instance   = TestModel.first

        instance.options.no_default_value_no_type_attribute.should == "no_default_value_no_type_attribute"
        instance.options.no_default_value_typed_attribute.should == 4567
        instance.options.no_type_attribute.should == "no_type_attribute"
        instance.options.typed_attribute.should == 8765
        instance.options.typed_attribute_no_default_value.should == 34
      end
    end
  end
  
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
        test_model.options.typed_attribute.should == 1234
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
      
      # restoring original type
      ModelOptions.attributes[:typed_attribute_no_default_value][:type] = :integer
    end

    it "remembers who is the owner model, so that it can be forced to a changed state when any attributes change" do
      options.__owner_object.should == test_model
    end
    
    it "sets the accessor __serialized_attribute to the name of its column that stored the tableless model instance, serialized" do
      options.__serialized_attribute.should == :options
    end
  end

end
