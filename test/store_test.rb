require File.join(File.dirname(__FILE__), *%w(helper))

class StoreTest < Test::Unit::TestCase
  TC = Yuki::Store::TokyoCabinet
  TY = Yuki::Store::TokyoTyrant
  
  context "a tokyo cabinet store" do
    context "with a valid config" do
      setup do
        @store = TC.new :file => "test.tct"
      end
    
      should "be valid" do
        assert @store.valid?
      end
    end
    
    context "without a valid config" do
      setup do
        @store = TC.new
      end
      
      should "not be valid" do
        assert !@store.valid?
      end
    end
  end
  
  context "a tokyo tyrant store" do
    context "with a valid config" do
      setup do
        @store = TY.new({
          :host => "localhost",
          :port => 45002
        })
      end

      should "be valid" do
        assert @store.valid?
      end
     end
     
     context "without a valid config" do
       setup do
         @store = TY.new
       end

       should "not be valid" do
         assert !@store.valid?
       end
     end
  end 
end