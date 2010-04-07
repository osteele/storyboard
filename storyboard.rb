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

  def draw_caption(context)
    time = self.time
    caption = nil
    for panel in @panels do
      break if time < 0
      caption = panel.caption || caption
      time -= panel.duration
    end
    @@caption_font = context.create_font('Helvetica', 10)
    context.text_font @@caption_font
    context.text(caption, 24, context.height - 24) if caption
  end

  class Panel
    attr_reader :duration, :owner, :stage, :avars, :caption

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
    define_method(:define_storyboard) do
      self.storyboard_settings = Object.new
      class << self.storyboard_settings
        attr_accessor :size, :scale, :color_mode, :background
        def reset!
          @size = [300, 300]
          @scale = [1.0, 1.0]
          @color_mode = nil
          @background = nil
        end
      end
      storyboard_settings.reset!
      storyboard_builder.instance_eval(&block)
    end
  end
end

class Sketch < Processing::App
  attr_accessor :storyboard_settings

  def storyboard_builder
    builder = Object.new
    class << builder
      attr_accessor :settings
      # DSL methods for inside of +screenplay+ block
      def size(x, y=nil)
        settings.size = [x, y || x]
      end
      def scale(x=1.0, y=nil)
        settings.scale = [x, y || x]
      end
      def color_mode(*args)
        settings.color_mode = args
      end
      def background(*args)
        settings.background = args
      end
    end
    builder.settings = self.storyboard_settings
    return builder
  end
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

    @broken = false
    @running = true
    #@make_movie = true

    self.define_storyboard

    xsize, ysize = storyboard_settings.size
    xscale, yscale = storyboard_settings.scale
    size xsize * xscale, ysize * yscale

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
      color_mode *storyboard_settings.color_mode if storyboard_settings.color_mode
      background *storyboard_settings.background if storyboard_settings.background
      push_matrix
      scale *storyboard_settings.scale
      smooth
      storyboard.draw_current_frame(self, running)
      pop_matrix
      storyboard.draw_caption(self)
      save_frame("build/frames/frame-####.png") if running and make_movie and storyboard.time <= storyboard.duration
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
