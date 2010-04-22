class Layout
  attr_accessor :objects

  def initialize(objects)
    @objects = objects
  end

  def setup_matrix(g)
    b = content_bounds
    w, h = bounds.x1 - bounds.x0, bounds.y1 - bounds.y0
    r = [g.width.to_f / w, g.height.to_f / h].min
    g.scale r, r
  end

  def apply
  end

  def content_bounds
    bs = objects.map(&:bounds)
    OpenStruct.new(:x0 => bs.map(&:x0).min, :y0 => bs.map(&:y0).min,
                   :x1 => bs.map(&:x1).max, :y1 => bs.map(&:y1).max)
  end
end
