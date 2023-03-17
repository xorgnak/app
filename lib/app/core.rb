module CORE
  LVLS = [
    :visitor,
    :promotor,
    :ambassador,
    :agent,
    :operator
  ]
  def self.[] k
    LVLS[k]
  end
end
