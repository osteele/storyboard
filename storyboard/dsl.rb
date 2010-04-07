require 'singleton'

module Storyboard
  class StoryboardBuilder
    include Singleton

    attr_reader :storyboard, :current_scene, :record_head, :verbose?

    def self.method_missing(name, *args, &block)
      return self.instance.send(name, *args, &block) if self.instance.respond_to?(name)
      super
    end

    def initialize
      reset!
    end

    def reset!
      @record_head = 0
    end

    def storyboard
      Storyboard.instance
    end

    def define_storyboard(&block)
      puts "Defining storyboard" if verbose?
      reset!
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

    def define_scene(name=nil, &block)
      @current_scene = Scene.new(name, storyboard.scenes.length + 1)
      storyboard.scenes << @current_scene
      puts "Define #{@current_scene.name}" if verbose?
      block.call
    end

    def define_panel(&block)
      unless current_scene
        @current_scene = Scene.new(nil, storyboard.scenes.length + 1)
        storyboard.scenes << current_scene
      end
      panel = Panel.new(storyboard, current_scene, block,
                        record_head, current_scene.panels.length + 1)
      current_scene.panels << panel
      storyboard.panels << panel
      puts "Define #{panel.name}" if verbose?
      @record_head += panel.duration
    end

    def pause(duration)
      @record_head += duration
    end
  end
end

def storyboard(&block)
  Storyboard::StoryboardBuilder.define_storyboard(&block)
end

def scene(name=nil, &block)
  Storyboard::StoryboardBuilder.define_scene(name, &block)
end

def panel(&block)
  Storyboard::StoryboardBuilder.define_panel &block
end

def reset_panels!
  Storyboard::StoryboardBuilder.reset!
  Storyboard::Storyboard.instance.reset_panels!
end

def pause(duration=1)
  Storyboard::StoryboardBuilder.pause(duration)
end
