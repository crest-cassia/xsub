require 'pp'
require 'json'
require 'fileutils'
require 'pry'
require "any_scheduler/version"
require "any_scheduler/template"

module AnyScheduler

  def self.scheduler(scheduler_type)
    case scheduler_type.to_sym
    when :none
      require "any_scheduler/schedulers/none"
      AnyScheduler::SchedulerNone.new
    when :torque
    when :pjm
    else
      raise "not supported type"
    end
  end

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

    def params_in_json
      JSON.pretty_generate(parameter_definitions)
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
