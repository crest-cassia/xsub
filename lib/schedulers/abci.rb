require 'date'
require 'open3'
require File.expand_path(File.dirname(__FILE__)+'/../scheduler')

module Xsub

  class Abci < Scheduler

    TEMPLATE = <<EOS
#!/bin/bash
#$ -l <%= resource_type_num %>
#$ -l h_rt=<%= walltime %>
#$ -N <%= name_job %>
#$ -p <%= priority %>
#$ -cwd
cd <%= File.expand_path(_work_dir) %>
LANG=C
. <%= _job_file %>
EOS

    PARAMETERS = {
      "resource_type_num" =>  { :description => "(resource_type)=(num)", :default => "rt_F=1", :format => '$'},
      "name_job" => { :description => "name of job", :default => "oacis_job", :format => '$'},
#      "group" => { :description => "user group", :default => "group_name", :format => '$'},
      "group" => { :description => "user group", :default => `groups | awk '{printf $2}'`, :format => '$'},      
      "priority" => { :description => "priority", :default => 0, :format => '^[0-9]\d*$'},
      "walltime" => { :description => "Limit on elapsed time", :default => "0:01:00", :format => '^\d+:\d{2}:\d{2}$'},
      
      "mpi_procs" => { :description => "MPI process", :default => 1, :format => '^[1-9]\d*$'},
      "omp_threads" => { :description => "OMP threads", :default => 1, :format => '^[1-9]\d*$'}
    }
    
    def validate_parameters(prm)
    end

    def submit_job(script_path, work_dir, log_dir, log, parameters)
      cmd = "cd #{File.expand_path(work_dir)} && qsub -g #{parameters["group"]} -o #{File.expand_path(log_dir)}/execute.log -e #{File.expand_path(log_dir)}/error.log #{File.expand_path(script_path)}"
      log.puts "cmd: #{cmd}", "time: #{DateTime.now}"
      ## [2019-12-18 I.Noda] to provide more informative error message.
      # output = `#{cmd}`
      #unless $?.to_i == 0
      #  log.puts "rc is not zero: #{output}"
      #  raise "rc is not zero: #{output}, #{File.expand_path(work_dir)}"
      #end
      (output, errorMsg, returnCode) = *(Open3.capture3(cmd))
      unless returnCode.to_i == 0
        errorInfo = ("return-code is not zero: code=#{returnCode.to_i}" + 
                     "\n\t cmd=#{cmd.inspect}" +
                     "\n\t output=#{output.inspect}" +
                     "\n\t error=#{errorMsg.inspect}" +
                     "\n\t workdir=#{File.expand_path(work_dir)}") ;
        log.puts(errorInfo)
        raise (errorInfo)
      end
      
      job_id = output.lines.to_a.last.split[2]
      log.puts "job_id: #{job_id}"
      {:job_id => job_id, :raw_output => output.lines.map(&:chomp).to_a }
    end

    def status(job_id)
      cmd = "qstat | grep #{job_id}"
      output = `#{cmd}`
      if $?.to_i == 0
        status = case output.lines.to_a.last.split[4]
        when /qw|hqw/
          :queued
        when /r/
          :running
        when /e/
          :finished
        else
          raise "unknown output: #{output}"
        end
      else
        status = :finished
      end
      { :status => status, :raw_output => output.lines.map(&:chomp).to_a }
    end

    def all_status
      cmd = "qstat -g c"
      output = `#{cmd}`
      output
    end

    def delete(job_id)
      cmd = "qdel #{job_id}"
      output = `#{cmd}`
      raise "failed to delete job: #{job_id}" unless $?.to_i == 0
      output
    end
  end
end

