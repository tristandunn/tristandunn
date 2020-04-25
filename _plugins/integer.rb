# frozen_string_literal: true

class Integer
  # Return the integer with the ordinal appended.
  #
  # @return [String] The ordinalized integer.
  def ordinalize
    "#{self}#{ordinal}"
  end

  private

  # Determine the ordinal for the integer.
  #
  # @return [String] The ordinal.
  def ordinal
    return "th" if (11..13).cover?(abs % 100)

    case abs % 10
    when 1 then "st"
    when 2 then "nd"
    when 3 then "rd"
    else        "th"
    end
  end
end
