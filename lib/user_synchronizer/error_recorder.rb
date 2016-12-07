
require 'json'
require 'awesome_print'

module UserSynchronizer
  module ErrorRecorder

    def read_errors(fname)
      each_error(fname) { |r| ap r }
    end

    def each_error(fname)
      fio = open_error_file(fname)
      fio.each_line do |l|
        yield JSON.parse(l.chomp)
      end
      fio.close
    end

    private

    def open_error_file(fname)
      File.open(fname)
    end

    def set_error_out(fname_or_stream = STDOUT)
      if fname_or_stream.is_a? String
        @error_out = File.open(fname_or_stream, 'w')
      else
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
