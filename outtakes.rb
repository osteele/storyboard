p "load #{Time.now}"

class << Object
  def deft(m, &block)
    p "deftx #{name}"
    define_method(m) do |*args|
      #$stderr.puts "before #{m}(#{args.inspect})"
      #ret = self.send("traced_#{m}", *args)
      #$stderr.puts "after #{m} - #{ret.inspect}"
      #ret
      p 'invoke'
      block.call(*args)
    end

    singleton_class.send :define_method, m do |*args|
      $stderr.puts "before #{m}(#{args.inspect})"
      ret = self.send("traced_#{m}", *args)
      $stderr.puts "after #{m} - #{ret.inspect}"
      ret
    end
  end
  
  def temporal(name)
    p "def #{singleton_class.object_id}"
    singleton_class.send :alias_method, :old_name, name
    # the next line doesn't introduce a new method into the global scope
    singleton_class.send :define_method, :newm1 do |*args|
      p "newm #{c.object_id}"
      self.send_method :old_name, *args
    end
    c = singleton_class
    # this method doesn't find draw_row in self, capture s_c, or current s_c
    define_method :newm2 do |*args|
      p "newm2 #{c.object_id}"
      self.send_method :draw_row, *args
    end
    singleton_class.send :define_method, name do |*args|
      p "shadowed"
      self.send_method :old_name, *args
    end
  end
end

def animate(&block)
end
