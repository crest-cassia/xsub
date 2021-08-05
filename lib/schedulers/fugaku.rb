require File.expand_path(File.dirname(__FILE__)+'/../scheduler')

module Xsub

  class Fugaku < Scheduler

    TEMPLATE = <<EOS
#!/bin/bash -x
#
#PJM --rsc-list "node=<%= node %>"
#PJM --rsc-list "rscgrp=<%= Fugaku.rscgrpname(node, elapse, low_priority_job) %>"
#PJM --rsc-list "elapse=<%= elapse %>"
#PJM --mpi "shape=<%= shape %>"
#PJM --mpi "proc=<%= mpi_procs %>"
#PJM --mpi "max-proc-per-node=<%= max_mpi_procs_per_node %>"
#PJM -s

. <%= _job_file %>
EOS

    PARAMETERS = {
      'mpi_procs' => { description: 'MPI process', default: 1, format: '^[1-9]\d*$' },
      'max_mpi_procs_per_node' => { description: 'Max MPI processes per node', default: 1, format: '^[1-9]\d*$' },
      'omp_threads' => { description: 'OMP threads', default: 1, format: '^[1-9]\d*$' },
      'elapse' => { description: 'Limit on elapsed time', default: '1:00:00', format: '^\d+:\d{2}:\d{2}$' },
      'node' => { description: 'Nodes', default: '1', format: '^\d+(x\d+){0,2}$' },
      'shape' => { description: 'Shape', default: '1', format: '^\d+(x\d+){0,2}$' },
      'low_priority_job' => { description: 'Low priority job(s)?', default: 'false', format: '^(true|false)$' }
    }

    def self.rscgrpname(node, elapse, low_priority_job)
      num_nodes = node.split('x').map(&:to_i).inject(:*)
      elapse_time_sec = elapse.split(':').map(&:to_i).inject {|result, value| result * 60 + value}
      is_low_priority_job = low_priority_job == 'true'

      if is_low_priority_job
        if num_nodes <= 384 && elapse_time_sec <= 43200 # <= 12h
          'small-free'
        elsif num_nodes <= 55296 && elapse_time_sec <= 43200 # <= 12h
          'large-free'
        else
          ''
        end
      else
        if num_nodes <= 384 && elapse_time_sec <= 259200 # <= 72h
          'small'
        elsif num_nodes <= 55296 && elapse_time_sec <= 86400 # <= 24h
          'large'
        else
          ''
        end
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

      low_priority_job = parameters['low_priority_job']
      raise 'low_priority_job must be "true" or "false"' unless ['true', 'false'].include?(low_priority_job)
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

    def parse_status(line)
      status =
        if line
          case line.split[3]
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
      { :status => status, :raw_output => [line] }
    end

    def status(job_id)
      output = `pjstat #{job_id}`
      if $?.success?
        parse_status(output.lines.grep(/^\s*#{job_id}/).last)
      else
        { :status => :finished, :raw_output => output }
      end
    end

    def multiple_status(job_id_list)
      output_list = `pjstat`.split(/\R/)
      job_id_list.map {|job_id| [job_id, parse_status(output_list.grep(/^s*#{job_id}/).last)]}.to_h
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
