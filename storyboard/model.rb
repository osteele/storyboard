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
        create_context(sketch, runner).instance_eval &@block
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

    def create_context(sketch, runner)
      scene.class.class_eval do
        attr_accessor :build_panel, :stage, :g
      end
      scene.instance_eval do
        def caption(*args); @build_panel.caption(*args); end
        def avar(*args); @build_panel.avar(*args); end
        def animate_by(*args); @build_panel.animate_by(*args); end
        def animate_to(*args); @build_panel.animate_to(*args); end
      end
      scene.build_panel = self
      scene.stage = runner.stage_manager
      scene.g = sketch
      scene
    end

    #
    # DSL methods
    #

    def caption(*msg)
      @caption = msg[0] if msg.any?
      return @caption
    end

    def avar(start=1.0, stop=nil, &block)
      if start.instance_of?(Array)
        avar = ColorAvar.new(start, stop)
      else
        start, stop = 0.0, start unless stop
        avar = AVar.new(start, stop, &block)
      end
      self.avars << avar
      return avar
    end

    def animate_by(target, getter, delta)
      start = target.send(getter).to_f
      animate_to(target, getter, start.to_f + delta.to_f)
    end

    def animate_to(target, getter, stop)
      start = target.send(getter).to_f
      setter = :"#{getter}="
      avar(start, stop) do |v| target.send(setter, v) end
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

  class DisplaySettings
    attr_accessor :size, :scale, :color_mode, :background
  end
end
