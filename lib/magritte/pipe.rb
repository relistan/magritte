require 'open3'
require 'stringio'
require_relative 'line_buffer'
require_relative 'iostreams'

# Acts as a two way pipe like the shell command line. We put
# data into a sub-process and capture the output.

module Magritte
  class Pipe
    def initialize(input, output=nil)
      @input  = input
      @output = output
      @line_by_line = false
    end

    def self.from_input_file(infile)
      self.from_input_stream(File.open(infile))
    end

    def self.from_input_stream(io)
      new(BlockStream.new(io))
    end

    def self.from_input_string(str)
      self.from_input_stream((StringIO.new(str || "")))
    end

    def out_to(io=nil, &block)
      unless block_given?
        @output = BlockStream.new(io)
        return self
      end

      if @line_by_line
        @output = LineBufferOutputStream.new(block, @record_separator || "\n")
      else
        @output = ProcOutputStream.new(block)
      end

      self
    end

    def separated_by(record_separator)
      @record_separator = record_separator
    end

    def line_by_line
      @line_by_line = true
      self
    end

    def filtering_with(command)
      raise "No output IO is set! Invoke out_to first!" unless @output

      Open3.popen2e(command) do |subproc_input, subproc_output, wait_thr|
        @subproc_output = BlockStream.new(subproc_output)
        @subproc_input  = BlockStream.new(subproc_input)

        clear_buffers

        while true do
          read_ready, write_ready, = select

          read_from_input

          if write_ready
            write_to_subproc
          end

          if read_ready
            read_from_subproc
            write_output
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
      stream.closed? ? nil : [stream.io]
    end

    def write_to_subproc
      bytes_written = @subproc_input.write(@write_data)
      @write_data = @write_data[bytes_written..-1]
    end

    def read_from_subproc
      @read_data += @subproc_output.read
    end

    def read_from_input
      @write_data += @input.read
    end

    def write_output
      bytes_written = @output.write(@read_data)
      @read_data = @read_data[bytes_written..-1]
    end

    def ready_to_close?
      @input.closed? && @write_data.empty? && @read_data.empty? && !@subproc_input.closed?
    end
  end
end

#Magritte::Pipe.from_input_file(ARGV[0]).out_to($stdout).filtering_with("build/bin/snapper --dbname=nt2012q1")
#Magritte::Pipe.from_input_stream($stdin).out_to($stdout).filtering_with("build/bin/snapper --dbname=nt2012q1")
#Magritte::Pipe.from_input_stream($stdin).out_to { |input| asdf += input; input.size}.filtering_with("cat")
