require File.expand_path(File.dirname(__FILE__)+'/../scheduler')

module Xsub

  class Cx400Nagoya < Scheduler

    TEMPLATE = <<EOS
#!/bin/bash -x
#
#PJM --rsc-list "vnode=<%= vnode %>"
#PJM --rsc-list "elapse=<%= elapse %>"
#PJM --rsc-list "rscgrp=<%= Cx400Nagoya.rscgrpname(vnode, elapse, uses_cx2550) %>"
#PJM --mpi "proc=<%= mpi_procs %>"
#PJM -s
cd ./<%= File.basename(_work_dir) %>
LANG=C
. <%= File.join('..', File.basename(_job_file)) %>
EOS

    PARAMETERS = {
      'mpi_procs' => { description: 'MPI process', default: 1, format: '^[1-9]\d*$' },
      'omp_threads' => { description: 'OMP threads', default: 1, format: '^[1-9]\d*$' },
      'elapse' => { description: 'Limit on elapsed time', default: '1:00:00', format: '^\d+:\d{2}:\d{2}$' },
      'uses_cx2550' => { description: 'Use CX2550?', default: 'true', format: '^(true|false)$' },
      'vnode' => { description: 'Nodes', default: '1', format: '^[1-9]\d*$' }
    }

    def self.rscgrpname(vnode, elapse, uses_cx2550)
      num_procs = vnode.to_i
      elapse_time_sec = elapse.split(':').map(&:to_i).inject(0) {|result, value| result * 60 + value}

      # Does not support cx-share, fx4-small and fx-middle2
      if uses_cx2550 == 'true'
        if num_procs <= 8 && elapse_time_sec <= 604800 # <= 168h
          'cx-small'
        elsif num_procs <= 32 && elapse_time_sec <= 259200 # <= 72h
          'cx-middle'
        elsif num_procs <= 128 && elapse_time_sec <= 259200 # <= 72h
          'cx-large'
        else
          ''
        end
      else # uses_cx2550 == 'false'
        if num_procs == 1 && elapse_time_sec <= 1209600 # <= 336h
          'cx2-single'
        elsif num_procs <= 8 && elapse_time_sec <= 259200 # <= 72h
          'cx2-small'
        elsif num_procs <= 32 && elapse_time_sec <= 259200 # <= 72h
          'cx2-middle'
        else
          ''
        end
      end
    end

    def validate_parameters(parameters)
      num_mpi_procs = parameters['mpi_procs'].to_i
      num_omp_threads = parameters['omp_threads'].to_i
      raise 'mpi_procs and omp_threads must be larger than or equal to 1' unless num_mpi_procs >= 1 and num_omp_threads >= 1

      uses_cx2550 = parameters['uses_cx2550']
      raise 'uses_cx2550 must be "true" or "false"' unless ['true', 'false'].include?(uses_cx2550)

      vnode = parameters['vnode'].to_i
      max_num_mpi_procs =
        if uses_cx2550 == 'true'
          vnode * 28
        else # parameters['uses_cx2550'] == 'false'
          vnode * 24
        end
      raise "mpi_procs must be less than or equal to #{max_num_mpi_procs}" unless num_mpi_procs <= max_num_mpi_procs
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
          case output.lines.last.split[3]
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
      { status: status, raw_output: output.lines.map(&:chomp) }
    end

    def all_status
      `pjstat`
    end

    def delete(job_id)
      output = `pjdel #{job_id}`
      raise "pjdel failed: rc=#{$?.to_i}" unless $?.success?
      output
    end
  end
end
