require 'stringio'
require 'json'
require 'user_synchronizer/error_recorder'

class MockErrorRecorder
  include UserSynchronizer::ErrorRecorder

  def initialize(stub = nil)
    @core = stub
  end

  def core
    @core
  end
end

describe UserSynchronizer::ErrorRecorder do
  let(:data) {
    [
      { 'a' => 'a1', 'b' => 'b1', 'c' => 'c1' },
      { 'a' => 'a2', 'b' => 'b2', 'c' => 'c2' },
      { 'a' => 'a3', 'b' => 'b3', 'c' => 'c3' },
    ]
  }
  let(:json) {
    "{\"a\":\"a1\",\"b\":\"b1\",\"c\":\"c1\"}\n" +
    "{\"a\":\"a2\",\"b\":\"b2\",\"c\":\"c2\"}\n" +
    "{\"a\":\"a3\",\"b\":\"b3\",\"c\":\"c3\"}\n"
  }
  describe '#each_error' do
    let(:mock) { MockErrorRecorder.new }
    let(:file) { StringIO.new(json) }

    before do
      allow(FileTest).to receive('exists?').and_return(true)
      allow(mock).to receive(:open_error_file).and_return(file)
    end

    it 'returns a hash generated from JSON each time reads a line' do
      i = 0
      mock.each_error("fname") do |r|
        expect(r).to eq(data[i])
        i += 1
      end
    end
  end

  describe '#record_error' do
    let(:io) { StringIO.new }
    let(:core) { double('core') }
    let(:mock) { MockErrorRecorder.new(core) }

    before do
      mock.send :set_error_out, io
      allow(core).to receive(:record_error) { |arg| arg }
      data.each { |r| mock.send(:record_error, r) }
    end

    it 'records passed data as json' do
      io.string.split("\n").each_with_index do |l, i|
        r = JSON.parse(l)
        expect(r).to eq(data[i])
      end
    end
  end 
end
