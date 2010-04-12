module Storyboard
  class Player
    attr_reader :storyboard, :stage_manager, :frame_rate, :options

    def initialize(storyboard, options)
      @storyboard = storyboard
      @options = options
      @stage_manager = StageManager.new
      @selected_panels = nil
      @frame_rate = 60.0
      rewind!
    end

    def panels
      storyboard.panels
    end

    def selected_panels
      return @selected_panels if @selected_panels
      panels = self.panels
      if options.scene
        scene_number = options.scene.to_i
        scene = storyboard.scenes.find { |s| s.number == scene_number }
        puts "Warning: no scene #{scene_number}" unless scene
        panels = scene ? scene.panels : []
        if options.panel
          panel_number = options.panel.to_i
          panels = panels.select { |p| p.number >= panel_number }
          puts "Warning: no panel #{panel_number}" unless panel
        end
        puts "Restricted to panels #{panels.first.name}..#{panels.last.name}, " +
          "#{panels.first.start_time} <= time < #{panels.last.end_time}" if panels.any?
      end
      @selected_panels = panels
    end

    def rewind!
      @current_frame = (self.start_time * frame_rate).to_i
      stage_manager.clear!
      panels.map &:reset
    end

    def start_time
      selected_panels.any? ? selected_panels.first.start_time : 0
    end

    def end_time
      selected_panels.any? ? selected_panels.last.end_time : 0
    end

    def done?
      self.time >= self.end_time
    end

    def time; @current_frame.to_f / frame_rate; end

    def time=(t)
      self.rewind! if t < self.time
      @current_frame = (t * frame_rate).to_i
    end

    def draw_frame(graphics, storyboard_settings, draw_frame_label)
      graphics.with_matrix do
        storyboard_settings.apply_frame_settings(graphics)
        draw_current_frame(graphics)
      end
      draw_frame_labels(graphics, draw_frame_label)
    end

    def draw_frame_labels(graphics, draw_frame_label)
      draw_frame_label(graphics) if draw_frame_label
      draw_caption(graphics)
    end

    def advance_frame
      @current_frame += 1
    end

    private

    # call each of the panels up through the current time, with an
    # argument that indicates the proportion through that panel
    def draw_current_frame(graphics)
      time = self.time
      for panel in panels do
        break if time < panel.start_time
        panel.run(graphics, self, [time - panel.start_time, panel.duration].min)
      end
      stage_manager.objects.each do |object|
        object.draw graphics
      end
    end

    def current_panel
      time = self.time
      return panels.first { |panel| panel.start_time < time and time < panel.end_time }
    end

    def current_caption
      time = self.time
      caption = nil
      for panel in panels do
        break if time < panel.start_time
        caption = panel.caption || caption
      end
      return caption
    end
    
    def draw_caption(graphics)
      caption = current_caption
      draw_caption_text(graphics, caption) if caption
    end

    public
    def draw_caption_text(graphics, caption)
      @@caption_font ||= graphics.create_font('Helvetica', 10)
      graphics.text_font @@caption_font
      graphics.text_align graphics.instance_eval("CENTER")
      height = graphics.text_descent + graphics.text_ascent
      graphics.text(caption, 0, graphics.height - height - 2,
                   graphics.width, height)
      graphics.text_align graphics.instance_eval("LEFT")
    end

    private
    def draw_frame_label(graphics)
      panel = current_panel
      @@frame_label_font ||= graphics.create_font('Helvetica', 8)
      graphics.text_font @@frame_label_font
      graphics.text("#{panel ? panel.name : nil} frame #{@current_frame}",
                   2, 2 + graphics.text_ascent + graphics.text_descent)
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

    def []=(key, object)
      key = key.to_sym
      return if @object_map[key] == object
      @objects.delete @object_map[key]
      @objects << object unless @objects.include?(object)
      @object_map[key] = object
    end

    def [](key)
      @object_map[key]
    end

    # adds an object, without a name
    def <<(object)
      @objects << object
    end

    def remove!(key)
      if key.instance_of?(Symbol)
        object = @object_map[key]
        @object_map.delete key
        @objects.delete object
      else
        # TODO remove the key
        object = key
        @objects.delete object
      end
    end

    def method_missing(name, *args)
      if name.to_s =~ /(.+)=$/ and args.length == 1
        self[$1] = args[0]
      elsif args.empty? and @object_map.include?(name)
        return @object_map[name]
      else
        super
      end
    end
  end
end
