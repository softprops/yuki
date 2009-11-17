require File.join(File.dirname(__FILE__), *%w(helper))
#require File.join(File.dirname(__FILE__), *%w(.. lib cast_system))

class Casting
  extend CastSystem
end
class CastSystemTest < Test::Unit::TestCase
  context "a cast system" do
    should "cast numeric values" do
      assert_equal 123, Casting.cast("123", :numeric)
    end
    
    should "uncast numeric values" do
      assert_equal "123", Casting.uncast(123, :numeric)
    end
    
    should "cast float values" do
      assert_equal 123.09, Casting.cast("123.09", :float)
    end
    
    should "uncast float values" do
      assert_equal "123.09", Casting.uncast(123.09, :float)
    end
    
    should "cast timestamp values" do
      now = Time.now
      assert_equal now.to_s, Casting.cast(now.to_i.to_s, :timestamp).to_s
    end
    
    should "uncast timestamp values" do
       now = Time.now
      assert_equal now.to_i.to_s, Casting.uncast(now, :timestamp)
    end
    
    should "cast boolean values" do
      assert_equal true, Casting.cast("true", :boolean)
      assert_equal false, Casting.cast("false", :boolean)
    end
    
    should "uncast boolean values" do
      assert_equal "true", Casting.uncast(true, :boolean)
      assert_equal "false", Casting.uncast(false, :boolean)
    end
    
    should "cast regex values" do
      assert_equal /[\@]+/, Casting.cast(/[\@]+/.to_s, :regex)
    end
    
    should "uncast regex values" do
      assert_equal /[\@]+/.to_s, Casting.uncast(/[\@]+/, :regex)
    end
    
    should "cast string values" do
      assert_equal "foo", Casting.cast("foo", :string)
    end
    
    should "uncast string values" do
      assert_equal "foo", Casting.uncast("foo", :string)
    end
    
    
  end
end