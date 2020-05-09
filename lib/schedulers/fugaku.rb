require File.expand_path(File.dirname(__FILE__)+'/../scheduler')

module Xsub

  class Fugaku < Scheduler

    TEMPLATE = <<EOS
#!/bin/bash -x
#
#PJM --rsc-list "node=<%= Fugaku.nodeoption(node, allocation) %>"
#PJM --rsc-list "rscunit=rscunit_ft01"
#PJM --rsc-list "rscgrp=<%= Fugaku.rscgrpname(node, elapse, covid19) %>"
#PJM --rsc-list "elapse=<%= elapse %>"
#PJM --mpi "shape=<%= shape %>"
#PJM --mpi "proc=<%= mpi_procs %>"
#PJM --mpi "max-proc-per-node=<%= max_mpi_procs_per_node %>"
#PJM -s
cd ./<%= File.basename(_work_dir) %>
LANG=C
. <%= File.join('..', File.basename(_job_file)) %>
EOS

    PARAMETERS = {
      'mpi_procs' => { description: 'MPI process', default: 1, format: '^[1-9]\d*$' },
      'max_mpi_procs_per_node' => { description: 'Max MPI processes per node', default: 1, format: '^[1-9]\d*$' },
      'omp_threads' => { description: 'OMP threads', default: 1, format: '^[1-9]\d*$' },
      'elapse' => { description: 'Limit on elapsed time', default: '1:00:00', format: '^\d+:\d{2}:\d{2}$' },
      'node' => { description: 'Nodes', default: '1', format: '^\d+(x\d+){0,2}$' },
      'allocation' => { description: 'Node allocation', default: '', format: '^(torus|mesh|noncont|)$' },
      'shape' => { description: 'Shape', default: '1', format: '^\d+(x\d+){0,2}$' },
      'covid19' => { description: 'Covid19', default: 'true', format: '^(true|false)$' }
    }

    def self.nodeoption(node, allocation)
      if allocation.empty?
        node
      else
        "#{node}:#{allocation}"
      end
    end

    def self.rscgrpname(_node, _elapse, covid19)
      # num_procs = node.split('x').map(&:to_i).inject(:*)
      # elapse_time_sec = elapse.split(':').map(&:to_i).inject(0) {|result, value| result * 60 + value}

      if covid19 == 'true'
        'covid19'
      else
        'dvall'
      end
    end

    def validate_parameters(parameters)
      num_procs = parameters['mpi_procs'].to_i
      num_threads = parameters['omp_threads'].to_i
      raise 'mpi_procs and omp_threads must be larger than or equal to 1' unless num_procs >= 1 and num_threads >= 1

      node_values = parameters['node'].split('x').map(&:to_i)
      shape_values = parameters['shape'].split('x').map(&:to_i)
      raise 'node and shape must be a same format like node=>4x3, shape=>1x1' unless node_values.length == shape_values.length
      raise 'each # in shape must be smaller than the one of node' unless node_values.zip(shape_values).all? {|node, shape| node >= shape}

      max_num_procs_per_node = parameters['max_mpi_procs_per_node'].to_i
      raise 'max_mpi_procs_per_node times omp_threads must be less than or equal to 48' unless max_num_procs_per_node * num_threads <= 48

      max_num_procs = shape_values.inject(:*) * max_num_procs_per_node
      raise "mpi_procs must be less than or equal to #{max_num_procs}" unless num_procs <= max_num_procs

      allocation = parameters['allocation']
      raise 'allocation must be empty, "torus", "mesh", or "noncont"' unless ['', 'torus', 'mesh', 'noncont'].include?(allocation)

      covid19 = parameters['covid19']
      raise 'covid19 must be "true" or "false"' unless ['true', 'false'].include?(covid19)
    end

    def submit_job(script_path, work_dir, log_dir, log, parameters)
      stdout_path = File.join( File.expand_path(log_dir), '%j.o.txt')
      stderr_path = File.join( File.expand_path(log_dir), '%j.e.txt')
      job_stat_path = File.join( File.expand_path(log_dir), '%j.i.txt')

      command = "cd #{File.expand_path(work_dir)} && pjsub #{File.expand_path(script_path)} -o #{stdout_path} -e #{stderr_path} --spath #{job_stat_path} < /dev/null"
      log.puts "cmd: #{command}"
      output = `#{command}`
      unless $?.success?
        log.puts "rc is not zero: #{output}"
        raise "rc is not zero: #{output}"
      end

      _, job_id = */Job (\d+) submitted/.match(output)
      unless job_id
        log.puts "failed to get job_id: #{output}"
        raise "failed to get job_id: #{output}"
      end

      log.puts "job_id: #{job_id}"
      { job_id: job_id, raw_output: output.lines.map(&:chomp) }
    end

    def status(job_id)
      output = `pjstat #{job_id}`
      status =
        if $?.success?
          last_line = output.lines.last
          if last_line
            case last_line.split[3]
            when /ACC|QUE/
              :queued
            when /RNA|RNP|RUN|RNE|RNO|SWO|SWD|SWI|HLD/
              :running
            when /EXT|RJT|CCL/
              :finished
            else
              :finished
            end
          else
            :finished
          end
        else
          :finished
        end
      { status: status, raw_output: output.lines.map(&:chomp) }
    end

    def all_status
      `pjstat --with-summary`
    end

    def delete(job_id)
      output = `pjdel #{job_id}`
      raise "pjdel failed: rc=#{$?.to_i}" unless $?.success?
      output
    end
  end
end
