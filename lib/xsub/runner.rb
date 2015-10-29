require 'optparse'
require 'json'
require 'logger'
require 'fileutils'

module Xsub

  module Status

    extend self

    def run(argv)
      OptionParser.new.parse!(argv)

      scheduler = Xsub.load_scheduler
      raise "scheduler type is not given" unless scheduler
      job_id = argv[0]
      if job_id
        output = scheduler.status(job_id)
      else
        output = scheduler.all_status
      end
      $stdout.print JSON.pretty_generate(output)
    end
  end

  module Delete

    extend self

    def run(argv)
      OptionParser.new.parse!(argv)

      scheduler = Xsub.load_scheduler
      raise "scheduler type is not given" unless scheduler
      job_id = argv[0]
      if job_id
        output = scheduler.delete(job_id)
        $stdout.print JSON.pretty_generate(output)
      end
    end
  end
end
