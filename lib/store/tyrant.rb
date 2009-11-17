module Yuki
  module Store
    class TokyoTyrant < Yuki::Store::AbstractStore
      require 'rufus/tokyo/tyrant'
      
      def initialize(config = {})
        @socket = config[:socket] if config.include? :socket
        @host, @port = config[:host], config[:port]
      end
    
      def valid?
        unless(socket_valid? || host_and_port_valid?)
          errors.size < 2
        else {}
        end
      end
        
      def stat
        open { |db| db.stat.inject('') { |s, (k, v)| s << "#{k} => #{v}\n" } }
      end
    
      protected
      
      def errors
        unless(socket_valid? || host_and_port_valid?)
          errs = {}
          unless(socket_valid?)
            errs.merge!({
              "invalid socket" => "Please provide a valid socket"
            })
          end  
          unless(host_and_port_valid?)
            errs.merge!({
              "invalid host and port" => "Please provde a valid host and port"
            })
          end
          errs
        else {}
        end
      end
      
      def aquire
        Rufus::Tokyo::TyrantTable.new(@socket? @socket : @host, @port)
      end
      
      private
      
      def socket_valid?
        @socket
      end
      
      def host_and_port_valid?
        @host && @port
      end
      
    end
  end
end