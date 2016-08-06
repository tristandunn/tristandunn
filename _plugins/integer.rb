class Integer
  def ordinal
    return "th" if (11..13).cover?(abs % 100)

    case abs % 10
    when 1 then "st"
    when 2 then "nd"
    when 3 then "rd"
    else        "th"
    end
  end

  def ordinalize
    "#{self}#{ordinal}"
  end
end
