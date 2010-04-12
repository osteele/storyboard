require 'storyboard'
require 'graphics-utils'

storyboard do
end

class Cube < DisplayObject3D
  def draw3d(g)
    g.lights
    g.translate g.width/2, g.height/2
    width, height = 100, 100
    g.rotate_y mouse.x / width * Math::PI
    g.rotate_x mouse.y / height * Math::PI
    g.box 90
  end
end

panel do
  caption "These are two numbers, represented as arrows."
  stage << Cube.new
end
