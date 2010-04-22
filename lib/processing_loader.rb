def setup; end # this tells the Processing runner to place methods in the Sketch class

$: << File.dirname(__FILE__)
require 'watch_require'
require 'graphics-utils'
require 'storyboard'

dft_panels = ARGV[0]
require dft_panels
