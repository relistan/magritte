module Magritte
  class LineBuffer
    include Enumerable

    attr_reader :buffer

    def initialize(record_separator="\n")
      @buffer = ""
      @record_separator = record_separator
    end

    def write(data)
      last_eol = data.rindex(@record_separator)
      return 0 unless last_eol

      data = data[0..(last_eol + @record_separator.size - 1)]
      @buffer += data
      data.size
    end

    def each_line(&block)
      raise ArgumentError.new("No block passed to each_line!") unless block_given?
      return if buffer.empty?

      lines = @buffer.split(@record_separator)
      lines.each(&block)
      @buffer = ""
    end

    alias_method :each, :each_line
  end
end
