require File.expand_path(File.dirname(__FILE__)+'/../scheduler')

module Xsub

  class Genkai < Scheduler

    TEMPLATE = <<EOS
#!/bin/bash -x
#
#PJM -L "rscgrp=<%= rscgrp %>"
#PJM -L "vnode_core=<%= vnode-core %>"
#PJM -L "elapse=<%= elapse %>"
#PJM -j
#PJM -S

. <%= _job_file %>
EOS

    PARAMETERS = {
      'elapse' => { description: 'Limit on elapsed time', default: '1:00:00', format: '^\d+:\d{2}:\d{2}$' },
      'vnode_core' => { description: 'Cores', default: '1', format: '^\d+(x\d+){0,2}$' },
      'rscgrp' => { description: 'Resource group', default: 'a-inter', format: '^[a-z]+-[a-z0-9]+$' }
    }

    def validate_parameters(parameters)
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
