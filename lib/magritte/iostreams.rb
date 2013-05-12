require 'forwardable'

module Magritte  
  class BlockStream
    extend Forwardable

    READ_BLOCK_SIZE = 512

    attr_reader :io
    def_delegators :@io, :flush, :closed?, :close

    def initialize(io)
      @io = io
    end

    def write(data)
      return 0 if data.empty?
      return 0 if @io.closed?

      begin
        @io.write_nonblock(data)
      rescue Errno::EAGAIN
        return 0
      end
    end

    def read
      begin
        data = @io.read_nonblock(READ_BLOCK_SIZE) unless @io.closed?
      rescue EOFError
        @io.close
      rescue Errno::EAGAIN
      end

      data || ""
    end
  end

  class ProcOutputStream
    def initialize(output_proc)
      @output = output_proc
    end

    def write(data)
      bytes_written = @output.call(data)
      raise 'output block must return number of bytes written!' unless bytes_written.is_a?(Fixnum)
      bytes_written
    end
  end

  class LineBufferOutputStream
    def initialize(output_proc, record_separator="\n") 
      @output_proc = output_proc;
      @buffer = LineBuffer.new(record_separator)
    end

    def write(data)
      bytes_written = @buffer.write(data)
      @buffer.each_line { |line| @output_proc.call(line) }
      bytes_written
    end
  end
end
