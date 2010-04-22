# Storyboard adaptor, back-end, for Ruby-Processing

# TODO move this to DSL
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
# Adaptor
#

class Sketch < Processing::App
  attr_reader :player, :movie_maker, :options, :file_watcher
  attr_accessor :running

  def make_movie?; options.movie; end
  def verbose?; options.verbose; end
  def running?; @running and not exception_occurred?; end
  def storyboard; Storyboard::Storyboard.instance; end

  def parse_options
    require 'optparse'
    require 'ostruct'
    @options = OpenStruct.new
    parser = OptionParser.new do |opts|
      opts.on('--scene NUMBER') do |opt| options.scene = opt end
      opts.on('--panel NUMBER') do |opt| options.panel = opt end
      opts.on('--scale SCALE', Float) do |opt| options.scale = opt end
      opts.on('--size GEOMETRY') do |opt| options.size = opt end
      opts.on('--gallery') do |opt| options.mode = :gallery end
      opts.on('--movie') do |opt| options.movie = true end
      opts.on('--verbose') do |opt| options.verbose = true end
    end
    begin
      parser.parse!(ARGV)
    rescue OptionParser::ParseError => e
      puts e
      exit 1
    end
  end

  def initialize_storyboard
    @initialized_storyboard = true
    @file_watcher = FileWatcher.new
    parse_options
  end

  def apply_option_overrides
    if options.scale
      s = options.scale
      storyboard_settings.scale = [s, s]
    end
    if options.size
      x, y = storyboard_settings.size.map(&:to_f)
      ratio = x / y
      case options.size
      when /^\d+$/
        x = y = options.size.to_f
      when /^(\d+)x(\d+)$/
        x = y = $1.to_f, $2.to_f
      when /^(\d+)x$/
        x = $1.to_f
        y = x / ratio
      when /^x(\d+)$/
        y = $1.to_f
        x = y * ratio
      else
        puts "Invalid format for --size: #{options.size}"
      end
        storyboard_settings.size = [x, y]
    end
  end

  def setup
    initialize_storyboard unless @initialized_storyboard

    puts "Starting at #{Time.now}" if verbose?

    reset_exception_state!
    @running = true
    @player = Storyboard::Player.new(storyboard, options)
    @player = Storyboard::GalleryPlayer.new(storyboard, options) if options.mode == :gallery
    @movie_maker = Storyboard::MovieMaker.new(self, make_movie?)

    with_rescue do
      self.run_storyboard_initializer
      apply_option_overrides
      storyboard_settings.apply_setup_settings(self)
    end

    movie_maker.start
    create_panel unless make_movie?

    self.run!
  end

  def rewind!
    puts "Execution resumed." if exception_occurred?
    reset_exception_state!
    player.rewind!
  end

  def draw
    with_rescue do
      if file_watcher.reload_changes
        reset_exception_state!
        self.setup if player.storyboard != storyboard
        self.rewind!
      end
    end
    if exception_occurred?
      background 0
      player.draw_caption_text(self, "Exception: #{exception_text}")
      return
    end
    with_rescue do
      player.draw_frame(self, storyboard_settings, :draw_frame_label => !make_movie?)
      player.advance_frame if running? and not player.done?
      movie_maker.add_frame if running?
    end
    movie_maker.done if player.done?
    exit if make_movie? and player.done?
  end

  def pause!; self.running = false; end

  def run!
    reset_exception_state!
    @running = true
    player.rewind! if player.done?
  end

  def time=(time)
    player.time = time
  end

  # def stroke_weight(w)
  #   if storyboard_settings.scale
  #     sx = storyboard_settings.scale[0]
  #     w = w.to_f / sx if sx < 1
  #   end
  #   super(w)
  # end
end


#
# Exception Handling
#

class Sketch < Processing::App
  private

  def exception_occurred?; @exception; end

  def exception_text
    "#{@exception.to_s} at #{@exception.backtrace.first.sub(/.*\//, '')}"
  end

  def reset_exception_state!
    @exception = nil
  end

  def with_rescue(&block)
    begin
      return block.call
    rescue Exception => e
      @exception = e
      puts "Exception occurred while running animation:"
      puts e.to_s
      puts e.backtrace.join("\n")
      puts "Execution halted."
    end
  end
end


#
# Control Panel
#

class Sketch < Processing::App
  load_library "control_panel"

  def create_panel
    if @control_panel
      @control_panel.hide
      @control_panel = nil
    end
    control_panel do |c|
      #c.slider :opacity
      c.slider(:Time, (player.start_time)..(player.end_time)) { |t| self.time = t; self.pause! }
      #c.menu(:options, ['one', 'two', 'three'], 'two') { }
      #c.checkbox(:paused) { |c| self.running = !c }
      c.button(:pause!)
      c.button(:run!)
      c.button(:rewind!)
      self.running = true
    end
  end
end


#
# Movie Maker
#

module Storyboard
  class MovieMaker
    def initialize(graphics, enabled)
      @graphics = graphics
      @enabled = enabled
    end

    def enabled?; @enabled; end

    def start
      return unless enabled?
      puts "Creating movie frames"
      require 'fileutils'
      FileUtils::rm_rf '/tmp/storyboard/frames'
    end

    def done; end

    def add_frame
      return unless enabled?
      @graphics.save_frame("/tmp/storyboard/frames/frame-####.png")
    end
  end
end


#
# Apply Display Settings
#

module Storyboard
  class DisplaySettings

    def apply_setup_settings(g)
      xsize, ysize = size || [300, 300]
      xscale, yscale = scale || [1.0, 1.0]
      g.size(xsize * xscale, ysize * yscale)
    end

    def apply_frame_settings(g)
      g.color_mode *color_mode if color_mode
      g.scale(*scale) if scale
      if true
        g.background *(background || [0])
      else
        g.fill *(background || [0])
        g.no_stroke
        g.rect 0, 0, g.width, g.height
        g.fill 1,0,1
      end
      g.smooth
      g.stroke_weight 2
    end
  end
end
