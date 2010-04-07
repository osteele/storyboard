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
    attr_reader :duration, :owner, :avars, :caption, :start_time, :number, :stage

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
        @stage = runner.stage_manager
        self.instance_eval &@block
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

    #
    # DSL methods
    #

    def caption(*msg)
      @caption = msg[0] if msg.any?
      return @caption
    end

    def avar(min=1.0, max=nil)
      min, max = 0.0, min unless max
      avar = AVar.new(min, max)
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

    def initialize(min, max)
      @min, @max = min, max
      @s = 0.0
    end

    def ease(s)
      if s < 0.5
      then 2*s*s
      else (1 - (2*s-1)*(2*s-3))/2
      end
    end

    def to_f
      return @min + ease(s) * (@max - @min)
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
