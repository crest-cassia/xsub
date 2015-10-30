require 'optparse'
require 'json'

module Xsub

  class Checker

    attr_reader :scheduler

    def initialize(scheduler)
      @scheduler = scheduler
    end

    def run(argv)
      OptionParser.new.parse!(argv)

      job_id = argv[0]
      if job_id
        output = @scheduler.status(job_id)
        $stdout.print JSON.pretty_generate(output)
      else
        output = @scheduler.all_status
        $stdout.print output
      end
    end
  end
end

