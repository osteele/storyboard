def arrow(x0, y0, x1, y1)
  s = 6
  da = 14 * Math::PI / 180
  line(x0, y0, x1, y1)
  a0 = Math::atan2(y1-y0, x1-x0) - Math::PI
  for i in [-da, da]
    a = a0 + i
    line(x1, y1, x1 + s * cos(a), y1 + s * sin(a))
    #print s, a
  end
end

def with_matrix(options, &block)
  push_matrix
  translate options[:dx] || 0, options[:dy] || 0 if options[:dx] or options[:dy]
  yield
ensure
  pop_matrix
end
