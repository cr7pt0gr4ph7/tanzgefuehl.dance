# pluralize
#
# A Liquid filter to make it easy to form correct plurals.
#
# Based on https://github.com/bdesham/pluralize

module Pluralize

  def pluralize(number, singular, plural = nil)
    number = number.to_i
    if number == 1
      "#{number} #{singular}"
    elsif plural.nil?
      "#{number} #{singular}s"
    else
      "#{number} #{plural}"
    end
  end

  def pluralize_word(number, singular, plural = nil)
    number = number.to_i
    if number == 1
      singular.to_s
    elsif plural.nil?
      "#{singular}s"
    else
      plural.to_s
    end
  end

end

Liquid::Template.register_filter(Pluralize)
