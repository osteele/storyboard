# The animation package defines keywords that invoke their blocks
# conditionally on the current frame, and also side-effect the system
# to affect the triggering conditions of subsequent animation keywords
# within the same frame

require 'singleton'

module Animation
  def self.do
    yield
  end
end

class Animator
  include Singleton
  attr_accessor :recording_head
  attr_reader :play_head
  attr_accessor :current_frame

  def initialize
    self.reset
  end

  def reset
    @current_frame = 0
  end

  def do_frame
    @recording_head = 0
    @play_head = @current_frame.to_f / 50
    yield
    @current_frame += 1
    puts "Frame #{current_frame}" if false
  end

  def call_between(t0, t1)
    p [t0, t1, play_head] if false
    yield if t0 <= play_head and play_head <= (t1 || play_head)
  end
end

def reset_animation
  Animator.instance.reset
end

# outer wrapper for all animation
def do_frame(&block)
  a = Animator.instance
  a.do_frame(&block)
end 

# call for the next dur after the current head position
def interval(dt=1, &block)
  t0 = Animator.instance.recording_head
  Animator.instance.call_between(t0, t0 + dt, &block)
end

# after dur s, call the block on each frame
def after(dur=1, &block)
  t0 = Animator.instance.recording_head
  Animator.instance.call_between(t0 + dur, nil, &block)
end

# invoke the block over the next dur, with an argument in [0.1..1.0].
# after that, apply the block to 1.0, continuously
def over(dur, &block)
  a = Animator.instance
  t0 = a.recording_head
  a.call_between(t0, nil) do
    # p [t0, a.play_head] if a.play_head < t0 + dur
    block.call([1.0, (a.play_head - t0) / dur.to_f].min)
  end
end

# advance the play head dur s (wait dur s before invoking the next animation block)
def wait_t(dur=1)
  Animator.instance.recording_head += dur
end

# call once, then twice, etc., up to a maximum of m.
def stacked(count, dur=1)
  yield
end
