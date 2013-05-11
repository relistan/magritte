require 'open3'
require 'stringio'
require_relative 'line_buffer'

# Acts as a two way pipe like the shell command line. We put
# data into a sub-process and capture the output.

module Magritte
  class Pipe
    READ_BLOCK_SIZE = 512

    def initialize(input, output=nil)
      @input  = input
      @output = output
      @line_by_line = false
    end

    def self.from_input_file(infile)
      self.from_input_stream(File.open(infile))
    end

    def self.from_input_stream(io)
      new(io)
    end

    def self.from_input_string(str)
      new(StringIO.new(str || ""))
    end

    def out_to(io=nil, &block)
      if block_given?
        @output = Proc.new(&block)
      else
        @output = io if io
      end

      self
    end

    def line_by_line
      @line_by_line = true
      @buffer = LineBuffer.new
      self
    end

    def filtering_with(command)
      raise "No output IO is set! Invoke out_to first!" unless @output

      Open3.popen2e(command) do |subproc_input, subproc_output, wait_thr|
        @subproc_output = subproc_output
        @subproc_input  = subproc_input

        clear_buffers

        while true do
          read_ready, write_ready, = select

          read_from_input

          if write_ready
            write_to_subproc
          end

          if read_ready
            read_from_subproc
            send_output
          end

          # We close the input to signal to the sub-process that we are
          # done sending data. It will close its output when processsing
          # is completed. That signals us to stop piping data.
          if ready_to_close?
            @subproc_input.flush
            @subproc_input.close
          end

          break if @subproc_output.closed?
        end

        raise Errno::EPIPE.new("sub-process dirty exit!") unless wait_thr.value == 0
      end
    end

    private

    def clear_buffers
      @write_data = ""
      @read_data  = ""
    end

    def select
      output = descriptor_array_for(@subproc_output)
      input  = descriptor_array_for(@subproc_input)
      IO.select(output, input, nil, 0.01)
    end

    def descriptor_array_for(stream)
      stream.closed? ? nil : [stream]
    end

    def write_to(io, data)
      return 0 if data.empty?
      return 0 if io.closed?

      begin
        io.write_nonblock(data)
      rescue Errno::EAGAIN
        return 0
      end
    end

    def write_to_subproc
      bytes_written = write_to(@subproc_input, @write_data)
      @write_data = @write_data[bytes_written..-1]
    end

    def read_from_subproc
      @read_data += read_from(@subproc_output)
    end

    def read_from_input
      @write_data += read_from(@input)
    end

    def send_output
      bytes_written = if @line_by_line && @output.is_a?(Proc)
        send_output_line_by_line
      else
        send_output_block
      end

      @read_data = @read_data[bytes_written..-1]
    end

    def send_output_line_by_line
      bytes_written = @buffer.write(@read_data)
      @buffer.each_line { |line| @output.call(line) }
      bytes_written
    end

    def send_output_block
      if @output.is_a?(Proc)
        bytes_written = @output.call(@read_data)
        raise 'output block must return number of bytes written!' unless bytes_written.is_a?(Fixnum)
        bytes_written
      else
        write_to(@output, @read_data)
      end

    end

    def read_from(io)
      begin
        data = io.read_nonblock(READ_BLOCK_SIZE) unless io.closed?
      rescue EOFError
        io.close
      rescue Errno::EAGAIN
      end

      data || ""
    end

    def ready_to_close?
      @input.closed? && @write_data.empty? && @read_data.empty? && !@subproc_input.closed?
    end
  end
end

#Magritte::Pipe.from_input_file(ARGV[0]).out_to($stdout).filtering_with("build/bin/snapper --dbname=nt2012q1")
#Magritte::Pipe.from_input_stream($stdin).out_to($stdout).filtering_with("build/bin/snapper --dbname=nt2012q1")
#Magritte::Pipe.from_input_stream($stdin).out_to { |input| asdf += input; input.size}.filtering_with("cat")
