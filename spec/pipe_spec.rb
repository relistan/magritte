require 'magritte/pipe'
require 'stringio'

describe 'Magritte::Pipe' do
  let(:infile) { File.join(File.dirname(__FILE__), 'fixtures/prisoner_of_zenda.txt') }
  let(:output) { StringIO.new }

  context 'handling input' do
    it 'opens a file when passed a filename' do
      File.should_receive(:open).with(infile)

      Magritte::Pipe.from_input_file(infile)
    end

    it 'creates a BlockStream' do
      Magritte::BlockStream.should_receive(:new)

      Magritte::Pipe.from_input_stream(StringIO.new)
    end

    it 'wraps a string in a StringIO' do
      mock_stringio = mock('stringio')
      StringIO.should_receive(:new).and_return(mock_stringio)
      Magritte::BlockStream.should_receive(:new).with(mock_stringio)

      Magritte::Pipe.from_input_string('asdf')
    end
  end

  context 'handling output' do
    it 'raises when no output has been set' do
      expect { Magritte::Pipe.from_input_file(infile).filtering_with('cat') }.to \
        raise_error(RuntimeError)
    end

    it 'calls a block for output when out_to is passed one' do
      buffer = ""
      input = "12345\n67890"
      Magritte::Pipe.from_input_string(input).out_to { |p| buffer += p; p.size }.filtering_with('cat')

      buffer.should == input
    end

    it 'raises when the output Proc does not return a size value' do
      expect { Magritte::Pipe.from_input_file(infile).out_to { |p| nil }.filtering_with('cat') }.to \
        raise_error('output block must return number of bytes written!')
    end

    it 'handles line-by-line output blocks' do
      buffer = []
      Magritte::Pipe.from_input_string("1234\n56789\n")
        .line_by_line
        .out_to { |p| buffer << p }.filtering_with('cat')

      buffer.should == %w{ 1234 56789 }
    end
  end

  context 'processing data' do
    it 'raises when the sub-process exits inappropriately' do
      expect { Magritte::Pipe.from_input_file(infile).out_to(output).filtering_with('bash -c "exit 1"') }.to \
        raise_error(Errno::EPIPE)
    end

    it 'raises when the sub-process cannot receive data' do
      expect { Magritte::Pipe.from_input_file(infile).out_to(output).filtering_with('iostat') }.to \
        raise_error(Errno::EPIPE)
    end

    it 'sends all input to the sub-process and out to the output stream' do
      Magritte::Pipe.from_input_file(infile).out_to(output).filtering_with('cat')
      output.string.split(/\n/).should have(6737).items
    end

    it 'correctly handles sub-processes that buffer heavily' do
      Magritte::Pipe.from_input_file(infile).out_to(output).filtering_with('sort')
      output.string.split(/\n/).should have(6737).items
    end

    it 'processes the data without any artifacts or other junk added to the stream' do
      Magritte::Pipe.from_input_file(infile).out_to(output).filtering_with('cat')
      output.string.should == File.read(infile)
    end
  end

  #it 'recovers when the end of the file was not a record separator' do
  #  buffer = []
  #  Magritte::Pipe.from_input_string("1234\n56789")
  #    .line_by_line
  #    .out_to { |p| buffer << p }.filtering_with('cat')

  #  buffer.should == %w{ 1234 56789 }

  #end
end
