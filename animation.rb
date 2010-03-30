# The animation package defines keywords that invoke their blocks
# conditionally on the current frame, and also side-effect the system
# to affect the triggering conditions of subsequent animation keywords
# within the same frame

require 'singleton'

class Animator
  include Singleton
  attr_accessor :recording_head
  attr_reader :play_head
  attr_accessor :current_frame
  attr_accessor :speed

  def initialize
    self.reset
  end

  def reset
    @current_frame = 0
    @blocks = []
    @speed = 60
  end

  def trace?
    return false
    return @current_frame < 20
  end

  def do_frame
    @recording_head = 0
    @play_head = @current_frame.to_f / @speed
    yield
    @current_frame += 1
    puts "Frame #{current_frame}" if false
  end

  def call_between(t0, t1, options={})
    return if play_head < t0
    return if t1 < play_head and not options[:persist]
    puts "block [#{t0}, #{t1}] (t = #{play_head})" if trace?
    @blocks << [t0, t1 || play_head]
    yield
    @blocks.pop
    puts "end block" if trace?
  end

  def block_param
    t0, t1 = @blocks[-1]
    s = (play_head - t0).to_f / (t1 - t0)
    return 0.0 if s.nan?
    p [play_head, t0, t1, s]  if trace?
    return [0.0, [1.0, s].min].max
  end
end

module Animation
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
  def over(dur=1, options={}, &block)
    a = Animator.instance
    t0 = a.recording_head
    a.call_between(t0, t0 + dur, options) do
      # p [t0, a.play_head] if a.play_head < t0 + dur
      block.call([1.0, (a.play_head - t0) / dur.to_f].min)
    end
  end

  # advance the play head dur s (wait dur s before invoking the next animation block)
  def wait_t(dur=1)
    Animator.instance.recording_head += dur
  end

  # return a value that varies from s0 to s1 of the immediately
  # enclosing animation block
  def slide(s0, s1, t0=nil, t1=nil)
    t = Animator.instance.block_param
    t = [0, [1, (t - t0) / (t1 - t0)].min].max if t0 and t1
    return s0 + t * (s1 - s0)
  end
end
