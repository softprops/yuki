module Yuki
  module Store
    class TokyoCabinet < Yuki::Store::AbstractStore
      require 'rufus/tokyo'
      
      def initialize(config = {})
        @file = config[:file]
      end
      
      def valid?
        errors.empty?
      end
    
      protected
      
      def errors
        unless @file =~ /[.]tct$/
          { "invalid file" => "Please provide a file in the format '{name}.tct'" }
        else {}
        end
      end
      
      def aquire
        Rufus::Tokyo::Table.new(@file)
      end
    end
  end
end