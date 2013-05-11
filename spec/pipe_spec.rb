require 'magritte/pipe'
require 'stringio'

describe 'Magritte::Pipe' do
  let(:infile) { File.join(File.dirname(__FILE__), 'fixtures/prisoner_of_zenda.txt') }
  let(:output) { StringIO.new }

  it 'opens a file when passed a filename' do
    File.should_receive(:open).with(infile)
    Magritte::Pipe.from_input_file(infile)
  end

  it 'raises when no output stream has been set' do
    expect { Magritte::Pipe.from_input_file(infile).filtering_with('cat') }.to \
      raise_error(RuntimeError)
  end

  it 'raises when the sub-process exits inappropriately' do
    expect { Magritte::Pipe.from_input_file(infile).out_to(output).filtering_with('bash -c "exit 1"') }.to \
      raise_error(Errno::EPIPE)
  end

  it 'raises when the sub-process cannot receive data' do
    expect { Magritte::Pipe.from_input_file(infile).out_to(output).filtering_with('uptime') }.to \
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

  it 'calls a block for output when out_to is passed one' do
    buffer = ""
    Magritte::Pipe.from_input_file(infile).out_to { |p| buffer += p; p.size }.filtering_with('cat')

    buffer.should == File.read(infile)
  end

  it 'raises when the output Proc does not return a size value' do
    expect { Magritte::Pipe.from_input_file(infile).out_to { |p| nil }.filtering_with('cat') }.to \
      raise_error('output block must return number of bytes written!')
  end
end
