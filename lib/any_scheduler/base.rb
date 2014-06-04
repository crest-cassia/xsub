require 'logger'

module AnyScheduler

  class Base

    def template
      self.class::TEMPLATE
    end

    def parameter_definitions
      self.class::PARAMETERS
    end

    def submit(job_scritps, parameters, opt = {logger: Logger.new(STDERR), work_dir: '.'})
      @logger = opt[:logger]
      @work_dir = opt[:work_dir]

      merged = default_parameters.merge( parameters )
      @logger.info "Parameters: #{merged.inspect}"
      validate_parameters(merged)

      outputs = job_scritps.map do |job_script|
        begin
          parent_script = render_template( merged.merge(job_file: File.expand_path(job_script)) )
          ps_path = parent_script_path(job_script)
          @logger.info "Parent script for #{job_script}: #{ps_path}"
          File.open( ps_path, 'w') {|f| f.write(parent_script); f.flush }
          @logger.info "Parent script has been written"
          output = submit_job(ps_path)
          output[:job_script] = job_script
          output
        rescue => ex
          @logger.error(ex)
        end
      end
      outputs
    rescue => ex
      @logger.error(ex)
    end

    def status(job_id)
      raise "Override me"
    end

    def delete(job_id)
      raise "Override me"
    end

    private
    def default_parameters
      Hash[ parameter_definitions.map {|k,v| [k,v[:default]] } ]
    end

    def render_template(parameters)
      Template.render( template, parameters)
    end

    def validate_parameters(parameters)
      # You can override this method
    end

    def parent_script_path( job_script )
      idx = 0
      parent_script = job_script + ".#{idx}.sh"
      while File.exist?(parent_script)
        idx += 1
        parent_script = job_script + ".#{idx}.sh"
      end
      parent_script
    end
  end
end
