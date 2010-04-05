# TODO move this into module

require 'singleton'
class Storyboard
  include Singleton

  attr_reader :objects, :object_map

  def initialize
    @panels = []
    @objects = []
    @object_map = {}
    @next_start = 0
    @current_frame = 0
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
      panel.do(context, [time, panel.duration].max)
      time -= panel.duration
    end
    self.objects.each do |object|
      object.draw context
    end
  end

  class Panel
    attr_reader :duration, :owner, :stage

    def initialize(owner, block, start_time)
      @owner = owner
      @block = block
      @start_time = start_time
      @duration = 1
      @called = false
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

    def do(sender, t)
      return if @called
      @called = true
      @block.call(self)
      puts "Panel: #{@caption}" #if @caption
    end

    def caption(msg)
      @caption = msg
    end

    def staged(name, object=nil)
      name, object = nil, name unless object
      owner.objects << object
    end
  end
end

def panel(&block)
  Storyboard.instance.define_panel &block
end

def draw_frame(sender)
  Storyboard.instance.draw_current_frame(sender)
end
