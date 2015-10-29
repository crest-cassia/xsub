require 'optparse'
require 'json'

module Xsub

  class Checker

    attr_reader :scheduler

    def initialize(scheduler)
      @scheduler = scheduler
      raise unless @scheduler.is_a?(Scheduler)
    end

    def run(argv)
      OptionParser.new.parse!(argv)

      job_id = argv[0]
      if job_id
        output = @scheduler.status(job_id)
      else
        output = @scheduler.all_status
      end
      $stdout.print output
    end
  end
end

