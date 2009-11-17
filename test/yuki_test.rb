require File.join(File.dirname(__FILE__), *%w(helper))

class Ninja
  include Yuki
  store :cabinet, :file => File.join(
    File.dirname(__FILE__), *%w(data test.tct)
  )
  has :weapon
  has :mp, :numeric
  has :last_kill, :timestamp
end

class YukiTest < Test::Unit::TestCase
  context "a model's attributes" do   
    
    should "have a default object type of string" do
      assert_equal '3', Ninja.new(:weapon => 3).weapon
    end
     
    should "provide a option for defaulting values" do
      class Paint 
        include Yuki
        has :color, :default => "red"
      end
      
      assert_equal "red", Paint.new.color     
    end
    
    should "be typed" do
      kill_time = Time.now
      
      object = Ninja.new({
        :weapon => "sword",               # string
        :mp => "45",                      # numeric
        :last_kill => kill_time.to_i.to_s # timestamp
      })
      
      assert_equal "sword", object.weapon
      assert_equal 45, object.mp
      assert_equal kill_time.to_s, object.last_kill.to_s
    end
    
    should "serialize and deserialize with type" do 
      kill_time = Time.now.freeze
      
      ninja = Ninja.new({
        :weapon => 'sword',         #string
        :mp => 45,                  # numeric
        :last_kill => kill_time     # timestamp
      }).save!   
        
      object = Ninja.get(ninja.key)
      assert_equal "sword", object.weapon
      assert_equal 45, object.mp
      assert_equal kill_time.to_s, object.last_kill.to_s
    end      
  
    should "be queryable" do
      ninja = Ninja.new(:weapon => 'knife')
      assert ninja.weapon?
      assert !ninja.mp?
      assert !ninja.last_kill?
    end
  
    should "should be immutable by default" do
      class ImmutableNinja 
        include Yuki
        has :weapon
      end
      
      assert !ImmutableNinja.new.respond_to?(:weapon=)
    end  
    
    should "provide an option for mutablility" do
      class MutableNinja 
        include Yuki
        has :weapon, :mutable => true
      end
      
      assert MutableNinja.new.respond_to?(:weapon=)
    end
  end
  
  context "a model's lifecyle operations" do
    should "provide callbacks" do
      
      class Sensei < Ninja
        attr_accessor :bs, :as, :bd, :ad
        def initialize
          @bs, @as, @bd, @ad = false, false, false, false
        end
        def before_save;    @bs = true; end
        def after_save;     @as = true; end
        def before_delete;  @bd = true; end
        def after_delete;   @ad = true; end
      end
      
      object = Sensei.new(:weapon => 'test')
      object.save!
      object.delete!  
      
      [:bs, :as, :bd, :ad].each { |cb| assert object.send(cb) }
    end
  end
  
  context "a model's serialized type" do
    should "default to the model's class name" do
      module Foo
        class Bar
          include Yuki
        end
      end
      
      assert "YukiTest::Foo::Bar", Foo::Bar.new.to_h['type']  
    end
  end

  context "a model's api methods" do
    should "provide a creation method" do
      assert Ninja.new.respond_to?(:save!)
    end
    
    should "provide an update method" do
      assert Ninja.respond_to?(:put)
      ninja  = Ninja.new.save!
      ninja = Ninja.put(ninja.key, { 'mp' => 6 })
      assert_equal(6, ninja.mp)
    end
    
    should "provide a deletion method" do
      ninja = Ninja.new.save!
      assert ninja.respond_to?(:delete!)
      ninja.delete!
      assert !Ninja.get(ninja.key)
    end
    
    should "provide query method(s)" do
      # write me
    end
    
  end

  context "an auditable model" do
    should "be soft deleted" do
      class ImmortalNinja
        include Yuki
        store :cabinet, :file => File.join(
          File.dirname(__FILE__), *%w(data test.tct)
        )
        has :mp, :numeric
        soft_delete!
      end
    
      ninja = ImmortalNinja.new(:mp => 6).save!
      ninja.delete!
      ninja = Ninja.get(ninja.key)
      assert ninja.deleted?
    end
  end
end