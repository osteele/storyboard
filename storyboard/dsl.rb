def storyboard(&block)
  puts "Defining storyboard"
  Sketch.class_eval do
    define_method(:define_storyboard) do
      self.storyboard_settings = Storyboard::DisplaySettings.new
      if ARGV.include?('--scale')
        s = ARGV[ARGV.index('--scale') + 1].to_f
        self.storyboard_settings.scale = s, s
      end
      storyboard_builder.instance_eval(&block)
    end
  end
end

def scene(name_or_number=nil, &block)
  block.call
end

def panel(&block)
  Storyboard::Storyboard.instance.define_panel &block
end

def reset_panels!
  Storyboard::Storyboard.instance.reset_panels!
end

def pause(duration=1)
  panel do end
end
