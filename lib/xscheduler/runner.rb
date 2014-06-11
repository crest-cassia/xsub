require 'optparse'
require 'json'
require 'logger'
require 'fileutils'

module XScheduler

  module Submitter

    Version = XScheduler::VERSION
    LOG_ROTATE_SIZE = 7

    extend self

    def run(argv)
      scheduler = XScheduler.load_scheduler
      parameters = {}
      logger = Logger.new(STDERR)
      work_dir = '.'

      OptionParser.new { |parser|
        parser.on('-t', '--show-template', 'show template') do |t|
          raise "scheduler type is not given" unless scheduler
          h = {parameters: scheduler.parameter_definitions, template: scheduler.template }
          $stdout.print JSON.pretty_generate(h)
          exit
        end

        parser.on('-p', '--parameters [PARAM]', 'parameters') do |param|
          parameters = JSON.load(param.sub(/^=/,'')) if param.size > 0
        end

        parser.on('-l', '--log [LOGFILE]', 'log file name') do |log|
          if log.size > 0
            logfile = log.sub(/^=/,'')
            logger = Logger.new(logfile , LOG_ROTATE_SIZE)
          end
        end

        parser.on('-d', '--dir [WORKDIR]', 'work directory') do |dir|
          if dir.size > 0
            work_dir = dir.sub(/^=/, '')
            FileUtils.mkdir_p(work_dir)
          end
        end

      }.parse!(argv)

      raise "scheduler type is not given" unless scheduler
      raise "you should give one argument" unless argv.size == 1
      output = scheduler.submit(argv[0], parameters, logger: logger, work_dir: work_dir)
      $stdout.print JSON.pretty_generate(output)

    end
  end
end
