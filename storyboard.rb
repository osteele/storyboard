# TODO move this into a module

require 'singleton'

class Storyboard
  include Singleton

  attr_reader :objects, :object_map

  def initialize
    reset_panels!
    rewind!
  end

  def reset_objects!
    @objects = []
    @object_map = {}
  end

  def reset_panels!
    @panels = []
    @next_start = 0
  end

  def rewind!
    @current_frame = 0
    self.reset_objects!
    @panels.map &:reset
  end

  def define_panel(&block)
    @panels << Panel.new(self, block, @next_start)
    @next_start += @panels.last.duration
  end

  def duration; @next_start; end

  def time; @current_frame / 60.0; end

  def time=(t)
    self.rewind! if t < self.time
    @current_frame = t * 60.0
  end

  # call each of the panels up through the current time, with an
  # argument that indicates the proportion through that panel
  def draw_current_frame(context, advance=true)
    time = self.time
    @current_frame += 1 if advance
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

        def clear!
          @owner.reset_objects!
        end

        def []=(key, value)
          @owner.objects << value
          @owner.object_map[key] = value
        end

        def [](key)
          @owner.object_map[key]
        end

        def remove!(key)
          object = @owner.object_map[key]
          @owner.object_map.delete key
          @owner.objects.delete object
        end

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
      unless @called
        @called = true
        #class << sketch; attr_accessor :panel; end
        #sketch.panel = self
        self.instance_eval &@block
        # Display this after invoking the block, since the blocks sets
        # the caption
        puts "Panel: #{@caption || '<<no caption>>'}"
      end
      s = t / duration
      avars.each do |avar| avar.s = s end
      @@caption_font = sketch.create_font('Helvetica', 10)
      sketch.text_font @@caption_font
      sketch.text(@caption, 12, 280) if @caption and t < duration
    end

    def reset
      @called = false
    end

    #
    # DSL methods
    #

    def caption(msg); @caption = msg; end

    def avar(min=1.0, max=nil)
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

# for now, this has no runtime effect
def scene(name_or_number=nil, &block)
  block.call
end

def panel(&block)
  Storyboard.instance.define_panel &block
end

def reset_panels!
  Storyboard.instance.reset_panels!
end

def pause(duration=1)
  panel do end
end

def storyboard(&block)
  puts "Defining storyboard"

  Sketch.class_eval do
    define_method(:run_block) do
      self.instance_eval(&block)
    end
  end
end

class Sketch < Processing::App
  # DSL methods for inside of +screenplay+ block
  def on_setup(&block); @on_setup = block; end
  def each_frame(&block); @each_frame = block; end
end


#
# Runner
#

class Sketch < Processing::App
  attr_accessor :make_movie
  attr_accessor :running

  def storyboard; Storyboard.instance; end

  def setup
    puts "Starting at #{Time.now}"
    self.run_block
    self.instance_eval(&@on_setup)
    @broken = false
    @running = true
    #@make_movie = true

    puts "creating panel!"
    create_panel
  end

  def rewind!
    Storyboard.instance.rewind!
    puts "Execution resumed." if @broken
    @broken = false
  end

  def draw
    self.rewind! if reload?
    return if @broken
    begin
      self.instance_eval(&@each_frame)
      storyboard.draw_current_frame(self, running)
      save_frame("build/frame-####.png") if running and make_movie and storyboard.time <= storyboard.duration
    rescue Exception => e
      puts "Exception occurred while running animation:"
      puts e.to_s
      puts e.backtrace.join("\n")
      puts "Execution halted."
      @broken = true
    end
  end

  def pause!; self.running = false; end

  def run!
    storyboard.time = 0 if storyboard.time > storyboard.duration
    self.running = true
    @broken = false
  end
end


#
# Control Panel
#

class Sketch < Processing::App
  load_library "control_panel"

  def create_panel
    control_panel do |c|
      #c.slider :opacity
      c.slider(:Time, 0..(storyboard.duration)) {|t| self.running = false; @broken = false; storyboard.time = t }
      #c.menu(:options, ['one', 'two', 'three'], 'two') { }
      #c.checkbox(:paused) { |c| self.running = !c }
      c.button(:pause!)
      c.button(:run!)
      c.button(:rewind!)
      self.running = true
    end
  end
end
