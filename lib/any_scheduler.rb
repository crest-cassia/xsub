require 'pp'
require 'json'
require 'pstore'
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
    Template.new(parameters).resolve(@template)
  end

  def submit(args, parameters)
    render_template(parameters)
  end
end
