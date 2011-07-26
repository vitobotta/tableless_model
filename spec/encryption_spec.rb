require "spec_helper"

class ModelSettings < ActiveRecord::TablelessModel
  attribute :some_attribute, :default => "default value" 
end

class SomeModel < ActiveRecord::Base
  has_tableless :settings => ModelSettings, :encryption_key => "a398bbfaac38c79e60a6e398efba8571"
end

describe SomeModel do
  context "when an encryption key has been specified for the tableless-based column" do
    let(:mock_encryptor) { mock(ActiveSupport::MessageEncryptor).as_null_object }

    before(:each) do
      ActiveSupport::MessageEncryptor.stub(:new).with("a398bbfaac38c79e60a6e398efba8571").and_return(mock_encryptor)
    end

    it "encrypts a tableless-based attribute when writing its attribute" do
      mock_encryptor.stub(:encrypt).and_return("encrypted...")

      subject.settings = ModelSettings.new(:some_attribute => "non default value")
      subject.read_attribute("settings").should == "encrypted..."
    end

    it "descripts a tableless-based attribute when reading its attribute" do
      mock_result = { :some_attribute => "bla bla bla" }
      
      subject.should_receive(:read_attribute).with(:settings).and_return("encrypted...")
      mock_encryptor.stub(:decrypt).with("encrypted...").and_return("serialised...")
      YAML.should_receive(:load).with("serialised...").and_return(mock_result)
      subject.settings.should == mock_result
    end
  end
end
