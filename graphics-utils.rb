public

class Arrow
  attr_reader :options
  def x0; options[:x0] || options[:x]; end
  def y0; options[:t0] || options[:y]; end
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
    @options = options
  end

  def draw(p)
    p.stroke(*options[:stroke].to_a) if options[:stroke]
    p.arrow(x0.to_f, y0.to_f, x1.to_f, y1.to_f)
  end
end

def arrow(x0, y0, x1, y1)
  return if (x0 - x1)**2 + (y0 - y1)**2 < 1
  s = 6
  da = 16 * Math::PI / 180
  line(x0, y0, x1, y1)
  a0 = Math::atan2(y1-y0, x1-x0) - Math::PI
  for i in [-da, da]
    a = a0 + i
    line(x1, y1, x1 + s * cos(a), y1 + s * sin(a))
    #print s, a
  end
end

def with_matrix(options={}, &block)
  push_matrix
  dx = (options[:dx] || 0).to_f
  dy = (options[:dy] || 0).to_f
  translate dx, dy if options[:dx] or options[:dy]
  yield
ensure
  pop_matrix
end
