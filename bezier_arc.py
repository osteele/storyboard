from math import acos, sin, cos, hypot, ceil, sqrt, radians, degrees
import warnings

def bezier_arc(x1, y1, x2, y2, start_angle=0, extent=90):
   
    """ Compute a cubic Bezier approximation of an elliptical arc.

    (x1, y1) and (x2, y2) are the corners of the enclosing rectangle.
    The coordinate system has coordinates that increase to the right and down.
    Angles, measured in degress, start with 0 to the right (the positive X axis)
    and increase counter-clockwise.
    The arc extends from start_angle to start_angle+extent.
    I.e. start_angle=0 and extent=180 yields an openside-down semi-circle.

    The resulting coordinates are of the form (x1,y1, x2,y2, x3,y3, x4,y4)
    such that the curve goes from (x1, y1) to (x4, y4) with (x2, y2) and
    (x3, y3) as their respective Bezier control points.
    """

    x1,y1, x2,y2 = min(x1,x2), max(y1,y2), max(x1,x2), min(y1,y2)

    if abs(extent) <= 90:
        frag_angle = float(extent)
        nfrag = 1
    else:
        nfrag = int(ceil(abs(extent)/90.))
        if nfrag == 0:
            warnings.warn('Invalid value for extent: %r' % extent)
            return []
        frag_angle = float(extent) / nfrag

    x_cen = (x1+x2)/2.
    y_cen = (y1+y2)/2.
    rx = (x2-x1)/2.
    ry = (y2-y1)/2.
    half_angle = radians(frag_angle) / 2
    kappa = abs(4. / 3. * (1. - cos(half_angle)) / sin(half_angle))

    if frag_angle < 0:
        sign = -1
    else:
        sign = 1

    point_list = []

    for i in range(nfrag):
        theta0 = radians(start_angle + i*frag_angle)
        theta1 = radians(start_angle + (i+1)*frag_angle)
        c0 = cos(theta0)
        c1 = cos(theta1)
        s0 = sin(theta0)
        s1 = sin(theta1)
        if frag_angle > 0:
            signed_kappa = -kappa
        else:
            signed_kappa = kappa
        point_list.append((x_cen + rx * c0,
                          y_cen - ry * s0,
                          x_cen + rx * (c0 + signed_kappa * s0),
                          y_cen - ry * (s0 - signed_kappa * c0),
                          x_cen + rx * (c1 - signed_kappa * s1),
                          y_cen - ry * (s1 + signed_kappa * c1),
                          x_cen + rx * c1,
                          y_cen - ry * s1))

    return point_list
