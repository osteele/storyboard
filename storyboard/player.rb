module Storyboard
  class Player
    attr_reader :storyboard, :stage_manager

    def initialize(storyboard)
      @storyboard = storyboard
      @stage_manager = StageManager.new
      rewind!
    end

    def panels
      storyboard.panels
    end

    def rewind!
      @current_frame = 0
      stage_manager.clear!
      panels.map &:reset
    end

    def done?
      self.time > storyboard.duration
    end

    def time; @current_frame / 60.0; end

    def time=(t)
      self.rewind! if t < self.time
      @current_frame = t * 60.0
    end

    def draw_frame(context)
      draw_current_frame(context)
    end

    def draw_frame_labels(context)
      draw_frame_label(context)
      draw_caption(context)
    end

    def advance_frame
      @current_frame += 1
    end

    private

    # call each of the panels up through the current time, with an
    # argument that indicates the proportion through that panel
    def draw_current_frame(context)
      time = self.time
      for panel in panels do
        break if time < 0
        panel.run(context, self, [time, panel.duration].min) if panel
        time -= panel.duration
      end
      stage_manager.objects.each do |object|
        object.draw context
      end
    end

    def current_panel
      time = self.time
      for panel in panels do
        return panel if time < 0
        time -= panel.duration
      end
      return nil
    end

    def current_caption
      time = self.time
      caption = nil
      for panel in panels do
        break if time < 0
        caption = panel.caption || caption
        time -= panel.duration
      end
      return caption
    end
    
    def draw_caption(context)
      caption = current_caption
      return unless caption
      @@caption_font ||= context.create_font('Helvetica', 10)
      context.text_font @@caption_font
      context.text(caption, 24, context.height - 10)
    end

    def draw_frame_label(context)
      panel = current_panel
      @@frame_label_font ||= context.create_font('Helvetica', 8)
      context.text_font @@frame_label_font
      context.text("#{panel ? panel.name : nil} frame #{@current_frame}", 2, 12)
    end
  end

  class StageManager
    attr_reader :objects

    def initialize
      clear!
    end

    def clear!
      @objects = []
      @object_map = {}
    end

    def []=(key, value)
      @objects << value
      @object_map[key] = value
    end

    def [](key)
      @object_map[key]
    end

    def remove!(key)
      object = @object_map[key]
      @object_map.delete key
      @objects.delete object
    end

    def method_missing(name, *args)
      if name.to_s =~ /(.+)=$/ and args.length == 1
        @objects << args[0]
        @object_map[$1.intern] = args[0]
      elsif args.empty? and @object_map.include?(name)
        return @object_map[name]
      else
        super
      end
    end
  end
end
