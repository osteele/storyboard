# Storyboard runner and back end for Ruby-Processing

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
  def make_movie?; @make_movie; end
  def running?; @running and not @broken; end
  def storyboard; Storyboard::Storyboard.instance; end

  def setup
    puts "Starting at #{Time.now}"

    @broken = false
    @running = true
    @make_movie = ARGV.include?('--movie')

    if make_movie?
      puts "Creating movie frames"
      require 'fileutils'
      FileUtils::rm_rf 'build/frames'
    end

    self.run_storyboard_initializer
    create_panel unless make_movie?

    storyboard_settings.apply_global_settings(self)
  end

  def rewind!
    storyboard.rewind!
    puts "Execution resumed." if @broken
    @broken = false
  end

  def draw
    self.rewind! if reload_watched_requires :all => true, :verbose => true
    return if @broken
    begin
      with_matrix do
        storyboard_settings.apply_frame_settings(self)
        storyboard.draw_current_frame(self)
        storyboard.advance_frame if running?
      end
      storyboard.draw_caption(self)
      save_frame("build/frames/frame-####.png") if running? and make_movie? and storyboard.time <= storyboard.duration
    rescue Exception => e
      puts "Exception occurred while running animation:"
      puts e.to_s
      puts e.backtrace.join("\n")
      puts "Execution halted."
      @broken = true
    end
    exit if make_movie? and storyboard.done?
  end

  def pause!; @running = false; end

  def run!
    @running = true
    @broken = false
    storyboard.rewind! if storyboard.done?
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
