class String
  def titleize
    gsub(/\b(?<!['’`])[a-z]/, &:capitalize)
  end
end
