require 'optparse'
require 'json'

module Xsub

  class Deleter

    attr_reader :scheduler

    def initialize(scheduler)
      @scheduler = scheduler
    end

    def run(argv)
      OptionParser.new.parse!(argv)

      raise "job_id is not given" unless argv.size == 1
      job_id = argv[0]
      if job_id
        output = scheduler.delete(job_id)
        $stdout.print output
      end
    end
  end
end

