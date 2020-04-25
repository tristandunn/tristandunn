# frozen_string_literal: true

class String
  # Titleize the string.
  #
  # @return [String] The titleized string.
  def titleize
    gsub(/\b(?<!['’`])[a-z]/, &:capitalize)
  end
end
