module HashExtentions
  def without(*args)
    return if Hash.respond_to? :without
    self.inject({}) { |wo, (k,v)| 
      wo[k] = v unless args.include? k
      wo
    }
  end
end
Hash.send :include, HashExtentions
module Yuki
  module Store
    class AbstractStore
      class InvalidStore < Exception; end
     
      # Determines if the current state of the store is valid
      def valid?; false; end
      
      # @see http://github.com/jmettraux/rufus-tokyo/blob/master/lib/rufus/tokyo/query.rb
      # expects
      # conditions = {
      #   :attr => [:operation, :value],
      #   :limit => [:offset, :max]
      #   :order => [:attr, :direction]
      # }
      # todo
      # db.union( db.prepare_query{|q| q.add(att, op, val)})
      #
      def filter(conditions = {}, &blk)
        ordering = extract_ordering!(conditions)
        max, offset = *extract_limit!(conditions)
        open { |db|
          db.query { |q|
            prepare_conditions(conditions) { |attr, op, val|
              q.add_condition(attr, op, val)
            }
            q.order_by(ordering[0])
            q.limit(max, offset) if max && offset
          }
        }
      end
      
      # unioned_conditions = db.union([
      #   { :attr => [:op, :val] }
      #   { :attr => [:op, :val2] }
      # ])
      def union(conditions)
        ordering = extract_ordering!(conditions)
        max, offset = *extract_limit!(conditions)
        open { |db|
          queries = conditions.inject([]) { |arr, cond|
            prepare_conditions(cond) { |attr, op, val|
              db.prepare_query { |q|
                q.add(attr, op, val)
                arr << q
              }
            }
            arr
          }
          db.union(*queries).map { |k, v| v.merge!(:pk => k) }
        }
      end
      
      def delete!(key)
       open { |db| db.delete(key) }
      end
      
      def keys
        open { |db| db.keys }
      end
    
      def any?
        open { |db| db.any? }
      end
      
      def empty?
        !any?
      end
      
      # Creates a new value. 
      # store << { 'foo' => 'bar' } => { 'foo' => 'bar', :pk => '1' }
      def <<(val)
        open { |db|
          key = key!(db, val)
          (db[key] = stringify_keys(val).without('pk')).merge(:pk => key)
        }
      end
    
      # Gets an value by key. 
      # store['1'] => { 'foo' => 'bar', :pk => '1' }
      def [](key)
        open { |db| db[key] }
      end
    
      # Merges changes into an value by key. 
      # store['1'] = { 'foo' => 'bar', 'baz' => 'boo' } => ...
      def []=(key, val)
        open { |db| 
          db[key] = (db[key] || {}).merge(val) 
        }.merge({
          'pk' => key
        })
      end
      
      protected
      
      # each store should override this with key-value
      # pairs representing the name and explaination of 
      # the error
      def errors
        {}
      end
      
      # Override this and return a db connection
      def aquire; end
      
      ## helpers

      def stringified_hash(h)
        h.inject({}) { |a, (k, v)| a[k.to_s] = v.to_s; a }
      end
      
      def stringify_keys(hash)
        hash.inject({}) { |stringified, (k,v)| stringified.merge({k.to_s => v}) }
      end
      
      private 
    
      def formatted_errors
        errors.inject([]) { |errs, (k,v)|
          errs << v
        }.join(', or ')
      end
      
      def extract_ordering!(hash)
        ordering = hash.delete(:order) || [:pk, :asc]
        ordering = [ordering] if(!ordering.kind_of?(Array))
        ordering[1] = :desc if ordering.size == 1
        ordering
      end
      
      def extract_limit!(hash)
        hash.delete(:limit)
      end
      
      def prepare_conditions(conditions, &blk)
        conditions.each { |attr, cond|
            validate_condition(cond)
            attr = '' if attr.to_s == 'pk'
            yield attr.to_s, cond[0], cond[1]
        }
      end
      
      def validate_condition(v)
        raise (
          ArgumentError.new("#{v.inspect} is not a valid condition") 
        ) if invalid_condition?(v)
        
        raise (
          ArgumentError.new("#{v[0]} is not a valid operator") 
        ) if invalid_op?(v[0])
      end

      def invalid_condition?(v)
        !(v && v.size == 2)
      end

      def invalid_op?(op)
        !Rufus::Tokyo::QueryConstants::OPERATORS.include?(op)
      end

      def key!(db, *args)
        db.genuid.to_s
      end
      
      def open(&blk)
        raise( 
          InvalidStore.new(formatted_errors)
        ) if !valid?
        Thread.current[:db] = begin
          db = aquire
          yield db
        ensure
          db.close if db
        end
      end   
    end
  end
end

# adapters

Yuki::Store.autoload :TokyoCabinet, File.join(
  File.dirname(__FILE__), 'cabinet'
)

Yuki::Store.autoload :TokyoTyrant, File.join(
  File.dirname(__FILE__), 'tyrant'
)