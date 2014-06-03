module AnyScheduler

  class Base

    def template
      self.class::TEMPLATE
    end

    def parameter_definitions
      self.class::PARAMETERS
    end

    def default_parameters
      Hash[ parameter_definitions.map {|k,v| [k,v[:default]] } ]
    end

    def render_template(parameters)
      Template.render( template, parameters)
    end

    def submit(job_scritps, parameters)
      merged = default_parameters.merge( parameters )

      outputs = job_scritps.map do |job_script|
        parent_script = render_template( merged.merge(job_file: job_script) )
        ps_path = parent_script_path(job_script)
        File.open( ps_path, 'w') {|f| f.write(parent_script); f.flush }
        submit_job(ps_path)
      end
      outputs
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