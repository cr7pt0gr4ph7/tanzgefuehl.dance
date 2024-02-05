# join
#
# A Liquid filter to make it easy to format lists as "1, 2 & 3".
# Intentionally overwrites the standard "join" filter.
module JoinWithTwoArguments

  def join(input, glue, final_glue = nil)
    return "" if input.nil?

    input_as_array = InputIterator.new(input, context).to_a
    return input_as_array.join(glue) if final_glue.nil?

    case input_as_array.length
    when 0
      ""
    when 1
      input_as_array[0].to_s
    when 2
      "#{input_as_array[0]}#{final_glue}#{input_as_array[1]}"
    else
      "#{input_as_array[0..-2].join(glue)}#{final_glue}#{input_as_array[-1]}"
    end
  end

  private

  attr_reader :context

  class InputIterator
    include Enumerable

    def initialize(input, context)
      @context = context
      @input   = if input.is_a?(Array)
        input.flatten
      elsif input.is_a?(Hash)
        [input]
      elsif input.is_a?(Enumerable)
        input
      else
        Array(input)
      end
    end

    def join(glue)
      to_a.join(glue.to_s)
    end

    def empty?
      @input.each { return false }
      true
    end

    def each
      @input.each do |e|
        e = e.respond_to?(:to_liquid) ? e.to_liquid : e
        e.context = @context if e.respond_to?(:context=)
        yield(e)
      end
    end
  end
end

Liquid::Template.register_filter(JoinWithTwoArguments)
