from AppKit import NSBezierPath

def arc0(self, x, y, radius, a0, a1):
    self._segment_cache = None
    self.inheritFromContext()
    self.moveto(x+r*cos(a0), y+r*sin(a0))
    self._nsBezierPath.appendBezierPathWithArcFromPoint_toPoint_radius_( (x+r*cos(a0), y+r*sin(a0)), (x+r*cos(a1), y+r*sin(a1)), radius)
    #self._nsBezierPath.appendBezierPathWithArcWithCenter_radius_startAngle_endAngle( (x1, y1), radius, a0, a1)

def arc(self, originx, originy, radius, startangle, endangle, clockwise=True):
        """Draw an arc"""
        self._segment_cache = None
        self.inheritFromContext() 
        if clockwise: # the clockwise direction is relative to the orientation of the axis, so it looks flipped compared to the normal Cartesial Plane
            self._nsBezierPath.appendBezierPathWithArcWithCenter_radius_startAngle_endAngle_clockwise_( (originx, originy), radius, startangle, endangle, 1)
        else:
            self._nsBezierPath.appendBezierPathWithArcWithCenter_radius_startAngle_endAngle_( (originx, originy), radius, startangle, endangle)

