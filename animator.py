class Animator:
    def __init__(self, globals):
        global TheAnimator
        TheAnimator = self
        self.globals = globals
        self.t0 = 0.0
        self.spans = []
    
    def sspan(self, dur):
        t0 = self.t0
        self.t0 += dur
        self.span = [t0, self.t0, []]
        self.spans.append(self.span)
        return self
    
    def move(self, name, x0, x1):
        self.span[2].append([name, x0, x1])
        return self
    
    def update1(self):
        t = self.globals['anim'] * self.t0
        for t0, t1, moves in self.spans:
            s = (t - t0) / (t1 - t0)
            s = max(0, min(1, s))
            for name, v0, v1 in moves:
                v = v0 + s * (v1 - v0)
                self.globals[name] = v

    @classmethod
    def update0(cls):
        global TheAnimator
        TheAnimator.update1()
