require File.join(File.dirname(__FILE__), *%w(store abstract))
require File.join(File.dirname(__FILE__),'cast_system')

# A wrapper for tokyo-x products for persistence of ruby objects
module Yuki 
  class InvalidAdapter < Exception; end
  
  def self.included(base)
    base.send :include, Yuki::Resource
  end
  
  module Resource
    
    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval { @store = nil }
      base.instance_eval { alias __new__ new }
      base.extend ClassMethods
      base.extend Validations
      base.instance_eval { 
        has :type 
        has :pk
      }
    end
   
    module Callbacks
      def before_save(); end
      def after_save(); end
      def before_delete(); end
      def after_delete(); end
    end
   
    module ClassMethods
      attr_reader :db
      
      # assign the current storage adapter and config
      def store(adapter, opts = {})
        @db = (case adapter
        when :cabinet then use_cabinet
        when :tyrant then use_tyrant
        else raise(
          InvalidAdapter.new(
            'Invalid Adapter. Try :cabinet or :tyrant.'
          )
        )
        end).new(opts)
      end
      
      def inherited(c)
        c.instance_variable_set(:@db, @db.dup || nil)
      end
      
      # Redefines #new method in order to build the object
      # from a hash. Assumes a constructor that takes a hash or a
      # no-args constructor
      def new(attrs = {})
        begin
          __new__(attrs).from_hash(attrs)
        rescue
          __new__.from_hash(attrs)
        end
      end
      
      # Returns all of the keys for the class's store
      def keys
        db.keys
      end
       
      # Gets all instances matching query criteria
      # :limit 
      # :conditions => [[:attr, :cond, :expected]]
      def filter(opts = {})
        build(db.filter(opts))
      end
      alias_method :all, :filter
      
      def union(opts = {})
        build(db.union(opts))
      end
      
      def soft_delete!
        has :deleted, :timestamp
        define_method(:delete!) { 
          self['deleted'] = Time.now 
          self.save!
        }
      end
      
      # Gets an instance by key
      def get(key)
        val = db[key]
        build(val)[0] if val && val[type_desc]
      end
      
      # Updates an instance by key the the given attrs hash
      def put(key, attrs)
        db[key] = attrs
        val = db[key]
        build(val)[0] if val && val[type_desc]
      end
      
      # An object Type descriminator
      # This is implicitly differentiates 
      # what a class a hash is associated with
      def type_desc
        'type'
      end
      
      # Attribute definition api.
      # At a minimum this method expects the name 
      # of the attribute. 
      #
      # This method also specifies type information 
      # about attributes. The default type is :default
      # which is a String. Other valid options for type
      # are.
      # :numeric
      # :timestamp
      # :float
      # :regex
      # 
      # opts can be
      #   :default - defines a default value to return if a value
      #              is not supplied
      #   :mutable - determines if the attr should be mutable. 
      #              true or false. (false is default)
      # 
      # TODO
      # opts planened to be supported in the future are
      # :alias      - altername name 
      # :collection - true or false
      #
      def has(attr, type = :string, opts = {})
        if type.is_a?(Hash)
          opts.merge!(type)
          type = :string
        end
        define_methods(attr, type, opts)
      end
      
      # Builds one or more instance's of the class from
      # a hash or array of hashes
      def build(hashes)
        [hashes].flatten.inject([]) do |list, hash|
          type = hash[type_desc] || self.to_s.split('::').last
          cls = resolve(type)
          list << cls.new(hash) if cls
          list
        end if hashes
      end
      
      # Resolves a class given a string or hash
      # If given a hash, the expected format is
      # { :foo => { :type => :Bar, ... } }
      # or
      # "Bar"
      def resolve(cls_def)
        if cls_def.kind_of? Hash
          class_key = cls_def.keys.first
          clazz = resolve(cls_def[class_key][:type])
          resource = clazz.new(info[class_key]) if clazz 
        else
          clazz = begin
            cls_def.split("::").inject(Object) { |obj, const| 
              obj.const_get(const) 
            } unless cls_def.strip.empty?
          rescue NameError => e
            puts "given #{cls_def} got #{e.inspect}"
            raise e
          end
        end
      end
      
      def define_methods(attr, type, opts = {})
        default_val = opts.delete(:default)
        mutable = opts.delete(:mutable) || false
        casted, uncasted = :"cast_#{attr}", :"uncast_#{attr}"
        define_method(casted) { |val| cast(val, type) }
        define_method(uncasted) { uncast(self[attr], type) }
        define_method(attr) { self[attr] || default_val }
        define_method(:"#{attr}=") { |v| self[attr] = v } if mutable 
        define_method(:"#{attr}?") { self[attr] }
      end
      
      private 
      
      def use_cabinet
        Yuki::Store::TokyoCabinet
      end
      
      def use_tyrant
        Yuki::Store::TokyoTyrant
      end
    end
    
    
    module Validations
      # config opts
      #   :msg => the display message
      def validates_presence_of(attr, config={})
        unless(send(attr.to_sym))
          add_error(
            "invalid #{attr}", 
            (config[:msg] || "#{attr} is required")
          )
        end
      end
    end
    
    module InstanceMethods
      include CastSystem
      include Callbacks
      
      def save!
        before_save
        validate!
        
        raise(
          Exception.new("Object not valid. #{formatted_errors}")
        ) unless valid?
        
        val = if(key) 
          db[key] = self.to_h
        else 
          db << self.to_h
        end
        
        data.merge!('pk' => (val[:pk] || val['pk']))
        after_save
        self
      end
      
      def delete!
        before_delete
        db.delete!(key)
        after_delete
        self
      end
      
      def errors
        @errors ||= {}
      end
      
      def add_error(k,v)
        errors.merge!({k,v})
      end
      
      def formatted_errors
        errors.inject([]) { |errs, (k,v)|
          errs << v
        }.join(', ')
      end
      
      def valid?
        errors.empty?
      end
      
      def validate!; end
      
      def key
        data['pk']
      end
      
      def to_h
        data.inject({}) do |h, (k, v)|
          typed_val  = method("uncast_#{k}").call
          h[k.to_s] = typed_val
          h
        end if data
      end
      
      def from_hash(h)
        type = { self.class.type_desc => self.class.to_s }
        h.merge!(type) unless h.include? self.class.type_desc
        
        h.each { |k, v|
          if attr_defined?(k)
            self[k.to_s] = v
          else
            p "#{k} is undef! for #{self.inspect}"
          end
        } if h
        
        self
      end
      
      # access attr as if model was hash
      def [](attr)
        data[attr.to_s]
      end
      
      # specifies the object 'type' to serialize
      def type
        self['type'] || self.class
      end
      
      protected
      
      def db
        self.class.db
      end
      
      def attrs
        data.dup
      end
      
      private
      
      def []=(attr, val) 
        val = method("cast_#{attr}").call(val)
        data[attr.to_s] = val
      end
    
      def attr_defined?(attr)
        respond_to?(:"cast_#{attr}")
      end
    
      def data
        @data ||= {}
      end  
    end  
  end
end