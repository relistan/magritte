require 'magritte/line_buffer'

describe Magritte::LineBuffer do
  let(:buffer) { Magritte::LineBuffer.new }

  context 'when writing' do
    it 'returns 0 when no line separators were written' do
      buffer.write("asdf").should == 0
    end

    it 'returns the number bytes written including the last record separator' do
      buffer.write("asdf\nfi").should == 5
    end

    it 'handles more than one line at a time' do
      buffer.write("asdf\nasdf\nfi").should == 10
    end
  end

  context 'when reading' do
    it 'only returns data that ends with a record separator - no partial records' do
      buffer.write("asdf\nasdf\nfi")
      buffer.buffer.should == "asdf\nasdf\n"
    end
  end

  context 'when iterating' do
    it 'returns each line one at a time' do
      buffer.write("asdf\nasdf\n")
      buffer.should have(2).items
    end

    it 'does not return partial lines' do
      buffer.write("asdf\nasdf\nfi")
      buffer.map {|x| x}.should == %w{ asdf asdf }
    end

    it 'clears the buffer once it has been iterated' do
      buffer.write("asdf\nasdf\nfi")

      buffer.map {|x| x}
      buffer.should have(0).items
    end

    it 'supports arbitrary record separators' do
      buffer = Magritte::LineBuffer.new("\r\n")
      buffer.write("asdf\r\nasdf\r\nasdf\r\n")
      
      buffer.map {|x| x}.should == %w{ asdf asdf asdf }
    end
  end
end
