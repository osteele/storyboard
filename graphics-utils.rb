public

def with_matrix(options={}, &block)
  push_matrix
  dx = (options[:dx] || 0).to_f
  dy = (options[:dy] || 0).to_f
  translate dx, dy if options[:dx] or options[:dy]
  yield
ensure
  pop_matrix
end

class Arrow
  attr_reader :options

  def x0; options[:x0] || options[:x]; end
  def y0; options[:y0] || options[:y]; end
  def x1; options[:x1] || x0.to_f + dx.to_f; end
  def y1; options[:y1] || y0.to_f + dy.to_f; end
  def dx; options[:dx] || 0; end
  def dy; options[:dy] || 0; end
  def x; x0; end
  def y; y0; end
  def stroke; options[:stroke]; end
  def x=(x); options.delete(:x0); options[:x] = x; end
  def y=(y); options.delete(:y0); options[:y] = y; end
  def dx=(dx); options[:dx] = dx; end
  def stroke=(s); options[:stroke] = s; end

  def initialize(options)
    @options = options.clone
  end

  def draw(g)
    g.stroke(*options[:stroke].to_a) if options[:stroke]
    draw_arrow(g, x0.to_f, y0.to_f, x1.to_f, y1.to_f, options)
  end

  def draw_arrow(g, x0, y0, x1, y1, options)
    return if (x0 - x1)**2 + (y0 - y1)**2 < 1
    g.line(x0, y0, x1, y1)
    return unless options[:tail]
    s = 6
    da = 16 * Math::PI / 180
    a0 = Math::atan2(y1-y0, x1-x0) - Math::PI
    for i in [-da, da]
      a = a0 + i
      g.line(x1, y1, x1 + s * cos(a), y1 + s * sin(a))
    end
  end
end

def arrow(x0, y0, x1, y1)
  return Arrow.new(:x0 => x0, :y0 => y0, :x1 => x1, :y1 => y1, :tail => true)
end

def line(x0, y0, x1, y1)
  return Arrow.new(:x0 => x0, :y0 => y0, :x1 => x1, :y1 => y1)
end

require 'ostruct'

class DisplayObject3D
  attr_reader :mouse, :g

  def draw(g)
    @g = g
    @mouse = nil
    image = g.buffer(300, 300, Sketch::P3D) do |b|
      draw3d(b)
    end
    g.image image, 0, 0
  end

  def mouse
    @mouse ||= OpenStruct.new(:x => @g.mouse_x.to_f, :y => @g.mouse_y.to_f)
  end

  def draw3d(g)
    g.lights
    g.translate g.width/2, g.height/2
    width, height = 100, 100
    g.rotate_y mouse.x / width * Math::PI
    g.rotate_x mouse.y / height * Math::PI
    g.box 90
  end
end
