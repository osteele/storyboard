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
  attr_reader :player
  attr_accessor :running

  def make_movie?; @make_movie; end
  def running?; @running and not @broken; end
  def storyboard; Storyboard::Storyboard.instance; end

  def setup
    puts "Starting at #{Time.now}"

    @broken = false
    @running = true
    @player = Storyboard::Player.new(storyboard)
    @make_movie = ARGV.include?('--movie')

    if make_movie?
      puts "Creating movie frames"
      require 'fileutils'
      FileUtils::rm_rf '/tmp/storyboard/frames'
    end

    self.run_storyboard_initializer
    create_panel unless make_movie?

    storyboard_settings.apply_global_settings(self)
    self.run!
  end

  def rewind!
    player.rewind!
    puts "Execution resumed." if @broken
    @broken = false
  end

  def draw
    if reload_watched_requires :all => true, :verbose => true
      self.setup if player.storyboard != storyboard
      self.rewind!
    end
    return if @broken
    begin
      with_matrix do
        storyboard_settings.apply_frame_settings(self)
        player.draw_frame(self)
        player.advance_frame if running? and not player.done?
      end
      player.draw_frame_labels(self, !make_movie?)
      save_frame("/tmp/storyboard/frames/frame-####.png") if make_movie? and running?
    rescue Exception => e
      puts "Exception occurred while running animation:"
      puts e.to_s
      puts e.backtrace.join("\n")
      puts "Execution halted."
      @broken = true
    end
    exit if make_movie? and player.done?
  end

  def pause!; self.running = false; end

  def run!
    @broken = false
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
