class Animator:
    def __init__(self, globals, the1=False):
        if the1:
            global TheAnimator
            TheAnimator = self
        self.globals = globals
        self.t0 = 0.0
        self.spans = []
        self.initial = {}
    
    def sspan(self, dur):
        t0 = self.t0
        self.t0 += dur
        self.span = (t0, self.t0, [])
        self.spans.append(self.span)
        return self
    
    def move(self, name, x0, x1):
        if name not in self.initial: self.initial[name] = x0
        self.span[2].append((name, x0, x1))
        return self

    def set(self, name, x):
        self.sspan(0)
        return self.move(name, x, x)

    def append(self, other):
        for name, value in other.initial.items():
            self.set(name, value)
        for t0, t1, moves in other.spans:
            self.spans.append((self.t0 + t0, self.t0 + t1, moves))
        self.t0 += other.t0
        return self
    
    def update1(self, frame=None):
        if frame is None:
            t = self.globals['anim'] * self.t0
        else:
            t = frame / 50.0
        set = {}
        for t0, t1, moves in self.spans:
            s = (t - t0) / (t1 - t0) if t1 > t0 else int(t > t0)
            s = max(0, min(1, s))
            for name, v0, v1 in moves:
                if t < t0 and name in set: continue
                v = v0 + s * (v1 - v0)
                set[name] = v
                self.globals[name] = v

    @classmethod
    def update0(cls, frame=None):
        global TheAnimator
        TheAnimator.update1(frame)
