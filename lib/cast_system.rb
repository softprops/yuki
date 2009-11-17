module CastSystem
  TO = {
    :numeric    => lambda { |v| v.to_i },
    :float      => lambda { |v| v.to_f },
    :timestamp  => lambda { |v|
      unless v.kind_of? Time
        Time.at(v.to_i)
      else
        v
      end
    },
    :boolean    => lambda { |v| 
      case v
      when "false" then false
      when "true" then true
      end
    }, 
    :regex      => lambda { |v| Regexp.new(v) },
    :string     => lambda { |v| v.to_s }
  }

  FROM = {
    :numeric    => lambda { |v| FROM[:string].call v },
    :float      => lambda { |v| FROM[:string].call v },
    :timestamp  => lambda { |v| FROM[:string].call v.to_i },
    :boolean    => lambda { |v| FROM[:string].call v }, 
    :regex      => lambda { |v| FROM[:string].call v },
    :string     => lambda { |v| v.to_s }
  }
  
  def cast(val, type)
    CastSystem::TO[type].call(val)
  end

  def uncast(val, type)
    CastSystem::FROM[type].call(val)
  end     
end