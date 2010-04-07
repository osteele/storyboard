require 'singleton'

module Storyboard
  class Storyboard
    include Singleton

    attr_reader :scenes, :panels, :objects, :object_map

    def initialize
      reset_panels!
    end

    def reset_panels!
      @scenes = []
      @panels = []
    end

    def duration
      panels.any? ? panels.last.end_time : 0
    end
  end

  class Panel
    attr_reader :duration, :owner, :scene, :avars, :caption, :start_time, :number, :stage

    def initialize(storyboard, scene, block, start_time, number)
      @owner = storyboard
      @scene = scene
      @number = number
      @block = block
      @start_time = start_time
      @duration = 1
      @called = false
      @avars = []
    end

    def end_time; start_time + duration; end

    def name
      "Scene #{@scene.number} panel #{@number}"
    end

    def run(sketch, runner, time)
      unless @called
        @called = true
        context(runner).instance_eval &@block
        # Display this after invoking the block, since the blocks sets
        # the caption
        puts "#{self.name}" + (self.caption ? ": #{self.caption}" : '')
      end
      update_avars(time)
    end

    def update_avars(time)
      s = time.to_f / duration
      avars.each do |avar| avar.s = s end
    end

    def reset
      @called = false
    end

    def context(runner)
      scene.class.class_eval do
        attr_accessor :build_panel, :stage
      end
      scene.instance_eval do
        def caption(*args); @build_panel.caption(*args); end
        def avar(*args); @build_panel.avar(*args); end
      end
      scene.build_panel = self
      scene.stage = runner.stage_manager
      scene
    end

    #
    # DSL methods
    #

    def caption(*msg)
      @caption = msg[0] if msg.any?
      return @caption
    end

    def avar(start=1.0, stop=nil)
      if start.instance_of?(Array)
        avar = ArrayAvar.new(start, stop)
      else
        start, stop = 0.0, start unless stop
        avar = AVar.new(start, stop)
      end
      self.avars << avar
      return avar
    end
  end

  class Scene
    attr_reader :panels, :number

    def initialize(name, number)
      @name = name
      @number = number
      @panels = []
    end

    def name
      "Scene #{number}"
    end
  end

  class AVar
    attr_accessor :s

    def initialize(start, stop)
      @start, @stop = start.to_f, stop.to_f
      @s = 0.0
    end

    def self.ease(s)
      if s < 0.5
      then 2*s*s
      else (1 - (2*s-1)*(2*s-3))/2
      end
    end

    def to_f
      return @start + self.class.ease(s) * (@stop - @start)
    end
  end

  class ArrayAvar
    attr_accessor :s

    def initialize(start, stop)
      @start, @stop = start, stop
      @s = 0
    end

    def to_a
      @start.zip(@stop).map { |a, b| a + AVar.ease(s) * (b - a) }
    end
  end

  class DisplaySettings
    attr_accessor :size, :scale, :color_mode, :background

    def apply_global_settings(sketch)
      xsize, ysize = size || [300, 300]
      xscale, yscale = scale || [1.0, 1.0]
      sketch.size(xsize * xscale, ysize * yscale)
    end

    def apply_frame_settings(sketch)
      sketch.color_mode *color_mode if color_mode
      sketch.background *background if background
      sketch.scale(*scale) if scale
      sketch.smooth
    end
  end
end
