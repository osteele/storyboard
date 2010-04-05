# TODO move this into a module

require 'singleton'

class Storyboard
  include Singleton

  attr_reader :objects, :object_map

  def initialize
    reset_panels!
    rewind!
  end

  def reset_panels!
    @panels = []
    @next_start = 0
  end

  def rewind!
    @objects = []
    @object_map = {}
    @current_frame = 0
    @panels.map &:reset
  end

  def define_panel(&block)
    @panels << Panel.new(self, block, @next_start)
    @next_start += @panels.last.duration
  end

  # call each of the panels up through the current time, with an
  # argument that indicates the proportion through that panel
  def draw_current_frame(context)
    time = @current_frame / 60.0
    # p "draw current panel {time} #{@panels.length}"
    @current_frame += 1
    for panel in @panels do
      break if time < 0
      panel.run(context, [time, panel.duration].min)
      time -= panel.duration
    end
    self.objects.each do |object|
      object.draw context
    end
  end

  class Panel
    attr_reader :duration, :owner, :stage, :avars

    def initialize(owner, block, start_time)
      @owner = owner
      @block = block
      @start_time = start_time
      @duration = 1
      @called = false
      @avars = []
      @stage = Object.new
      class << @stage
        attr_writer :owner
        def method_missing(name, *args)
          if name.to_s =~ /(.+)=$/ and args.length == 1
            @owner.objects << args[0]
            @owner.object_map[$1.intern] = args[0]
          elsif name.to_s !~ /=$/ and args.empty? and @owner.object_map.include?(name)
            return @owner.object_map[name]
          else
            super
          end
        end
      end
      @stage.owner = @owner
    end

    def run(sketch, t)
      s = t / duration
      avars.each do |avar| avar.s = s end
      return if @called
      @called = true
      #class << sketch; attr_accessor :panel; end
      #sketch.panel = self
      self.instance_eval &@block
      puts "Panel: #{@caption}"
    end

    def reset
      @called = false
    end

    #
    # DSL methods
    #

    def caption(msg); @caption = msg; end

    def avar(min=0.0, max=nil)
      min, max = 0.0, min unless max
      avar = AVar.new(min, max)
      self.avars << avar
      return avar
    end
  end

  class AVar
    attr_accessor :s

    def initialize(min, max)
      @min, @max = min, max
      @s = 0.0
    end

    def to_f
      return @min + s * (@max - @min)
    end
  end
end

#
# DSL
#

def panel(&block)
  Storyboard.instance.define_panel &block
end

def reset_panels!
  Storyboard.instance.reset_panels!
end

class Sketch < Processing::App
  def on_setup(&block); @on_setup = block; end
  def each_frame(&block); @each_frame = block; end
end

#
# Runner
#

def storyboard(&block)
  puts "Defining storyboard"

  Sketch.class_eval do
    define_method(:setup) do
      puts "Starting at #{Time.now}"
      self.instance_eval(&block)
      self.instance_eval(&@on_setup)
      @broken = false
    end

    def rewind!
      Storyboard.instance.rewind!
      puts "Execution resumed." if @broken
      @broken = false
    end

    define_method(:draw) do
      self.rewind! if reload?
      return if @broken
      begin
        self.instance_eval(&@each_frame)
        #draw_frame(self)
        Storyboard.instance.draw_current_frame(self)
      rescue Exception => e
        puts "Exception occured while running animation:"
        puts e.to_s
        puts e.backtrace.join("\n")
        puts "Execution halted."
        @broken = true
      end
    end
  end
end
