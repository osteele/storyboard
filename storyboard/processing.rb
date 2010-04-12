# Storyboard adaptor and back end for Ruby-Processing
require 'watch_require'

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
  attr_reader :player, :movie_maker
  attr_accessor :running

  def make_movie?; @make_movie; end
  def running?; @running and not @broken; end
  def storyboard; Storyboard::Storyboard.instance; end

  def setup
    puts "Starting at #{Time.now}"

    reset_exception_state!
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
    reset_exception_state!
    player.rewind!
    puts "Execution resumed." if @broken
  end

  def draw
    reload_changes
    if exception_occurred?
      background 0
      player.draw_caption_text(self, "Exception: #{exception_text}")
      return
    end
    with_rescue do
      player.draw_frame(self, storyboard_settings, !make_movie?)
      player.advance_frame if running? and not player.done?
      movie_maker.add_frame if running?
    end
    movie_maker.done if player.done?
    exit if make_movie? and player.done?
  end

  def reload_changes
    return if exception_occurred? and watched_require_mtime == exception_time
    reloaded = with_rescue do reload_watched_requires :all => true, :verbose => true end
    if reloaded
      self.setup if player.storyboard != storyboard
      self.rewind!
    end
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
end


#
# Exception Handling
#

class Sketch < Processing::App
  private

  attr_reader :exception_time

  def exception_occurred?; @exception; end

  def exception_text
    "#{@exception.to_s} at #{@exception.backtrace.first.sub(/.*\//, '')}"
  end

  def reset_exception_state!
    @broken = false
    @exception = nil
  end

  def with_rescue(&block)
    reset_exception_state!
    begin
      return block.call
    rescue Exception => e
      puts "Exception occurred while running animation:"
      puts e.to_s
      puts e.backtrace.join("\n")
      puts "Execution halted."
      @broken = true
      @exception = e
      @exception_time = watched_require_mtime
    end
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

    def apply_setup_settings(g)
      xsize, ysize = size || [300, 300]
      xscale, yscale = scale || [1.0, 1.0]
      g.size(xsize * xscale, ysize * yscale)
    end

    def apply_frame_settings(g)
      g.color_mode *color_mode if color_mode
      g.background *(background || [0])
      g.scale(*scale) if scale
      g.smooth
      g.stroke_weight 2
    end
  end
end
