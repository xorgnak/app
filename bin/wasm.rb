class Z4
  @@X = 0
  export
  def self.set x
    @@X = x
  end
  export
  def self.get
    @@X
  end
  export
  def self.send m
    self.send(m)
  end
end
