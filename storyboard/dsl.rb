require 'singleton'

module Storyboard
  class StoryboardBuilder
    include Singleton

    attr_reader :storyboard, :current_scene

    def self.method_missing(name, *args, &block)
      return self.instance.send(name, *args, &block) if self.instance.respond_to?(name)
      super
    end

    def storyboard
      Storyboard.instance
    end

    def define_storyboard(&block)
      puts "Defining storyboard"
      Sketch.class_eval do
        define_method(:run_storyboard_initializer) do
          self.storyboard_settings = DisplaySettings.new
          if ARGV.include?('--scale')
            s = ARGV[ARGV.index('--scale') + 1].to_f
            self.storyboard_settings.scale = s, s
          end
          storyboard_builder.instance_eval(&block)
        end
      end
    end

    def define_scene(name_or_number=nil, &block)
      block.call
    end

    def define_panel(&block)
      storyboard.define_panel(&block)
    end

    # TODO record the actual duration
    def pause(duration)
      define_panel do end
    end
  end
end

def storyboard(&block)
  Storyboard::StoryboardBuilder.define_storyboard(&block)
end

def scene(name_or_number=nil, &block)
  Storyboard::StoryboardBuilder.define_scene(name_or_number, &block)
end

def panel(&block)
  Storyboard::StoryboardBuilder.define_panel &block
end

def reset_panels!
  Storyboard::Storyboard.instance.reset_panels!
end

def pause(duration=1)
  Storyboard::StoryboardBuilder.pause(duration)
end
