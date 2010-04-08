# Storyboard runner and back end for Ruby-Processing

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
# Runner
#

class Sketch < Processing::App
  attr_reader :player, :movie_maker
  attr_accessor :running

  def make_movie?; @make_movie; end
  def running?; @running and not @broken; end
  def storyboard; Storyboard::Storyboard.instance; end

  def setup
    puts "Starting at #{Time.now}"

    self.reset_exception_state!
    @running = true
    @player = Storyboard::Player.new(storyboard)
    @make_movie = ARGV.include?('--movie')
    @movie_maker = Storyboard::MovieMaker.new(self, make_movie?)

    with_rescue do
      self.run_storyboard_initializer
      storyboard_settings.apply_setup_settings(self)
    end

    movie_maker.start
    create_panel unless make_movie?

    self.run!
  end

  def rewind!
    self.reset_exception_state!
    player.rewind!
    puts "Execution resumed." if @broken
  end

  def draw
    reload_changes
    if @exception
      background 0
      player.draw_caption_text(self, "Exception: #{@exception.to_s} at #{@exception.backtrace.first.sub(/.*\//, '')}")
      return
    end
    begin
      player.draw_frame(self, storyboard_settings, !make_movie?)
      player.advance_frame if running? and not player.done?
      movie_maker.add_frame if running?
      save_frame("/tmp/storyboard/frames/frame-####.png") if make_movie? and running?
    rescue Exception => e
      puts "Exception occurred while running animation:"
      puts e.to_s
      puts e.backtrace.join("\n")
      puts "Execution halted."
      @broken = true
      @exception = e
    end
    movie_maker.done if player.done?
    exit if make_movie? and player.done?
  end

  def reload_changes
    reloaded = with_rescue do reload_watched_requires :all => true, :verbose => true end
    if reloaded
      self.setup if player.storyboard != storyboard
      self.rewind!
    end
  end

  def reset_exception_state!
    @broken = false
    @exception = nil
  end

  def with_rescue(&block)
    self.reset_exception_state!
    begin
      return block.call
    rescue Exception => e
      puts "Exception occurred while running animation:"
      puts e.to_s
      puts e.backtrace.join("\n")
      puts "Execution halted."
      @broken = true
      @exception = e
    end
  end

  def pause!; self.running = false; end

  def run!
    self.reset_exception_state!
    @running = true
    player.rewind! if player.done?
  end

  def time=(time)
    player.time = time
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

    def apply_setup_settings(sketch)
      xsize, ysize = size || [300, 300]
      xscale, yscale = scale || [1.0, 1.0]
      sketch.size(xsize * xscale, ysize * yscale)
    end

    def apply_frame_settings(sketch)
      sketch.color_mode *color_mode if color_mode
      sketch.background *background if background
      sketch.scale(*scale) if scale
      sketch.smooth
      sketch.stroke_weight 2
    end
  end
end
