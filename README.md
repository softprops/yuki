# Yuki

a model wrapper for key-value objects around tokyo products (cabinet/tyrant) 
    
# Play with Ninjas

    class Ninja
      include Yuki
      store :cabinet, :path => "path/to/ninja.tct"
      has :color,     :string, :default => "black"
      has :name,      :string
      has :mp,        :numeric
      has :last_kill, :timestamp
    end
    
    # Tyrant requires tokyo tyrant to be started
    #   ttserver -port 45002 data.tct
    class Ninja
      include Yuki
      store :tyrant, :host => "localhost", :port => 45002
      # ...
    end
    
    class Ninja
      include Yuki
      store :cabinet, :path => "/path/to/ninja.tct"
      has :color, :default => "black"
      has :name, :string, :default => "unknown"
      has :mp, :numeric
      has :last_kill, :timestamp
      
      # object will remain in the store after deletion
      # with 'deleted' # => Time of deletion
      soft_delete!

      def before_save
        puts "kick"
      end

      def after_save
        puts "young blood..."
      end

      def before_delete
        puts "stabs murderer"
      end

      def after_delete
        puts "fights as ghost"
      end

      def validate!
        puts "ensure ninjatude"
      end

      # hook for serialization
      # (green ninjas get more mp when serialized)
      def to_h
        if color == "green"
          super.to_h.merge({
            "mp" => (mp + 1000).to_s
          })
        else
          super
        end
      end
    end

    # queryable attributes
    Ninja.new.mp? # false

    ninja = Ninja.new(:mp => 700, :last_kill => Time.now)

    ninja.mp? # true
    
    # crud
    ninja.save!
    ninja.update!
    ninja.delete!
    
    Ninja.filter({
      :color => [:eq, 'red'],
      :mp => [:gt, 40],
      :order => :last_kill
    }) # => all red ninjas with mp > 40
    
    Ninja.union([{
      :color => [:eq, 'red'],
      :mp => [:gt, 40],
    }, {
        :color => [:eq, 'black']
    }]) # => all black ninjas mixed with red ninjas with mp > 20
    
    Ninja.first
    
    Ninja.last
    
    Ninja.keys
    
    Ninja.any?
    
    Ninja.empty?
    
    Ninja.build([
      { ... },
      { ... },
      { ... }
    ]) # 3 ninjas built from 3 hashes
    
## Install
    > make sure to have the following tokyo products installed
      - tokyocabinet-1.4.36 or greater
      - tokyotyrant-1.1.37 or greater
      - [install tokyo products]:(@ http://openwferu.rubyforge.org/tokyo.html)

    > rip install git://github.com/softprops/yuki      
    
    > include Yuki in your model
    
    > run with it

2009 Doug Tangren (softprops)