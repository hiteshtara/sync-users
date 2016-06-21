
require 'json'
require 'awesome_print'

module UserSynchronizer
  module ErrorRecorder

    def read_errors(fname)
      each_error(fname) { |r| ap r }
    end

    def each_error(fname)
      unless FileTest.exists?(fname)
        puts "File Not Found: #{fname}"
        return
      end

      IO.foreach(fname) do |l|
        yield JSON.parse(l.chomp)
      end
    end

    private

    def set_error_out(fname_or_stream = STDOUT)
      if fname_or_stream.is_a? String
        @error_out = File.open(fname_or_stream, 'w')
      elsif fname_or_stream.is_a? File
        @error_out = fname_or_stream
      end
    end

    def error_out
      @error_out ||= STDOUT
    end

    def record_error(h)
      h = core.record_error(h)
      error_out.puts JSON.generate(h) 
    end
  end
end
