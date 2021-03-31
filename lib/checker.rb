require 'optparse'
require 'json'

module Xsub

  class Checker

    attr_reader :scheduler

    def initialize(scheduler)
      @scheduler = scheduler
      @is_multiple_mode = false
    end

    def run(argv)
      OptionParser.new{|parser|
        parser.on('-m', '--multiple') {|v| @is_multiple_mode = v }
      }.parse!(argv)

      job_id = argv[0]
      if argv.size < 1
        output = @scheduler.all_status
        $stdout.print output
      elsif @is_multiple_mode
        output = @scheduler.multiple_status(argv)
        $stdout.print JSON.pretty_generate(output)
      else
        output = @scheduler.status(argv[0])
        $stdout.print JSON.pretty_generate(output)
      end
    end
  end
end

