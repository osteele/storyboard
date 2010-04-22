module Storyboard
  class AVar
    attr_accessor :s

    def initialize(start, stop, &block)
      @start, @stop = start.to_f, stop.to_f
      @s = 0.0
      @block = block
    end

    def s=(value)
      changed = @s != value
      @s = value
      @block.call(self.to_f) if changed and not @block.nil?
    end

    def self.ease(s)
      if s < 0.5
      then 2*s*s
      else (1 - (2*s-1)*(2*s-3))/2
      end
    end

    def to_f
      return @start + self.class.ease(s) * (@stop - @start)
    end
  end

  class ArrayAvar
    attr_accessor :s

    def initialize(start, stop)
      @start, @stop = start, stop
      @s = 0
    end

    def to_a
      @start.zip(@stop).map { |a, b| a + AVar.ease(s) * (b - a) }
    end
  end

  class ColorAvar
    import "java.awt.Color"
    attr_accessor :s

    def initialize(start, stop)
      @start, @stop = start, stop
      @rgb_start = hsb2rgb(*start)
      @rgb_stop = hsb2rgb(*stop)
      @s = 0
    end

    def to_a
      rgb = @rgb_start.zip(@rgb_stop).map { |a, b| a + AVar.ease(s) * (b - a) }
      rgb2hsb(*rgb)
    end

    def rgb2hsb(r, g, b)
      r,g,b = [r,g,b].map { |c| (255 * c).to_i }
      java.awt.Color.RGBtoHSB(r, g, b, nil).to_a
    end

    def hsb2rgb(h, s, b)
      color = java.awt.Color.getHSBColor(h, s, b)
      return [:getRed, :getGreen, :getBlue].map { |m| color.send(m) / 255.0 }
    end
  end
end
