require 'pp'
require 'json'
require 'fileutils'
require 'pry'
require "any_scheduler/version"
require "any_scheduler/template"

module AnyScheduler

  extend self

  @template = <<EOS
#!/bin/bash
LANG=C
#PBS -l nodes=<%= num_nodes %>:ppn=<%= ppn %>
#PBS -l walltime=<%= elapsed %>
. <%= job_file %>
EOS

  @param = {
    "num_nodes" => { description: "Number of nodes", default: 1},
    "ppn" => { description: "Process per nodes", default: 4},
    "elapsed" => { description: "Limit on elapsed time", default: "1:00:00"}
  }

  SCHEDULER_WORK_DIR = '~/anyscheduler'

  def show_template
    print @template
  end

  def params_in_json
    JSON.pretty_generate(@param)
  end

  def render_template(parameters)
    Template.render(@template, parameters)
  end

  def submit(args, parameters)
    merged = parameters.merge( Hash[ @param.map {|k,v| [k,v[:default]] } ] )

    args.each do |job_file|
      script = write_job_script( merged.merge(job_file: job_file) )
      cmd = "nohup bash #{script} > /dev/null 2>&1 < /dev/null & basename #{script}"
      output = `#{cmd}`
      $?.to_i == 0 ? output : "failed"
    end
  end

  def write_job_script(parameters)
    FileUtils.mkdir_p( File.expand_path(SCHEDULER_WORK_DIR) )
    script = File.expand_path( File.join( SCHEDULER_WORK_DIR, "job.sh" ) )
    File.open(script, 'w') { |io|
      io.print render_template(parameters)
      io.flush
      io.close
    }
    script
  end
end
