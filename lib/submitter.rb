require 'optparse'
require 'json'
require 'logger'
require 'fileutils'

module Xsub

  class Submitter

    LOG_ROTATE_SIZE = 7

    attr_reader :scheduler, :parameters, :script,
                :logger, :work_dir, :log_dir

    def initialize(scheduler)
      @scheduler = scheduler
      @parameters = {}
      @script = nil
      @work_dir = '.'
      @log_dir = '.'
    end

    def run(argv)
      parse_arguments(argv)
      merge_default_parameters
      verify_parameter_format
      @scheduler.validate_parameters(@parameters)
      parent_script_path = prepare_parent_script
      output = @scheduler.submit_job( parent_script_path, @work_dir, @log_dir )
      $stdout.print JSON.pretty_generate(output)
    end

    def parse_arguments(argv)
      OptionParser.new { |parser|
        parser.on('-t', '--show-template', 'show template') do |t|
          h = { parameters: @scheduler.class::PARAMETERS,
                template: @scheduler.class::TEMPLATE.lines.map(&:chomp)
              }
          $stdout.print JSON.pretty_generate(h)
          exit
        end

        parser.on('-p', '--parameters [PARAM]', 'parameters') do |param|
          @parameters = JSON.load(param.sub(/^=/,'')) if param.size > 0
        end

        parser.on('-l', '--log [LOGDIR]', 'log directory name') do |log|
          if log.size > 0
            @log_dir = log.sub(/^=/,'')
            FileUtils.mkdir_p(@log_dir)
            log_file = File.join(@log_dir, 'xsub.log')
          end
        end

        parser.on('-d', '--dir [WORKDIR]', 'work directory') do |dir|
          if dir.size > 0
            @work_dir = dir.sub(/^=/, '')
            FileUtils.mkdir_p(@work_dir)
          end
        end

      }.parse!(argv)

      raise "no job script is given" unless argv.size == 1
      @script = argv[0]
    end

    def merge_default_parameters
      @scheduler.class::PARAMETERS.each do |key,definition|
        @parameters[key] ||= definition[:default]
      end
    end

    def verify_parameter_format
      param_def = @scheduler.class::PARAMETERS
      redundant = @parameters.keys - param_def.keys
      unless redundant.empty?
        raise "unknown parameter is given: #{redundant}.inspect"
      end

      param_def.each do |key,definition|
        unless @parameters[key].to_s =~ Regexp.new(definition[:format])
          raise "invalid parameter format: #{key} #{@parameters[key]} #{definition[:format]}"
        end
      end
    end

    def prepare_parent_script
      merged = @parameters.merge(job_file: File.expand_path(@script) )
      rendered = Template.render(@scheduler.class::TEMPLATE, merged)
      ps_path = parent_script_path( @script )
      File.open(ps_path, 'w') do |f|
        f.write rendered
        f.flush
      end
      ps_path
    end

    def parent_script_path( job_script )
      idx = 0
      parent_script = File.join(@work_dir, File.basename(job_script,'.sh') + "_xsub.sh")
      while File.exist?(parent_script)
        idx += 1
        parent_script = File.join(@work_dir, File.basename(job_script,'.sh') + "_xsub#{idx}.sh")
      end
      File.expand_path(parent_script)
    end
  end
end
