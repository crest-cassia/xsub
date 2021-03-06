require 'date'
require File.expand_path(File.dirname(__FILE__)+'/../scheduler')

module Xsub

  class Torque < Scheduler

    TEMPLATE = <<EOS
#!/bin/bash -x
#PBS -l nodes=<%= mpi_procs.to_i*omp_threads.to_i/ppn.to_i %>:ppn=<%= ppn %>
#PBS -l walltime=<%= walltime %>
. <%= _job_file %>
EOS

    PARAMETERS = {
      "mpi_procs" => { :description => "MPI process", :default => 1, :format => '^[1-9]\d*$'},
      "omp_threads" => { :description => "OMP threads", :default => 1, :format => '^[1-9]\d*$'},
      "ppn" => { :description => "Process per nodes", :default => 1, :format => '^[1-9]\d*$'},
      "walltime" => { :description => "Limit on elapsed time", :default => "24:00:00", :format => '^\d+:\d{2}:\d{2}$'}
    }

    def validate_parameters(prm)
      mpi = prm["mpi_procs"].to_i
      omp = prm["omp_threads"].to_i
      ppn = prm["ppn"].to_i
      unless mpi >= 1 and omp >= 1 and ppn >= 1
        raise "mpi_procs, omp_threads, and ppn must be larger than 1"
      end
      unless (mpi*omp)%ppn == 0
        raise "(mpi_procs * omp_threads) must be a multiple of ppn"
      end
    end

    def submit_job(script_path, work_dir, log_dir, log, parameters)
      cmd = "qsub #{File.expand_path(script_path)} -d #{File.expand_path(work_dir)} -o #{File.expand_path(log_dir)} -e #{File.expand_path(log_dir)}"
      log.puts "cmd: #{cmd}", "time: #{DateTime.now}"
      output = `#{cmd}`
      unless $?.to_i == 0
        log.puts "rc is not zero: #{output}"
        raise "rc is not zero: #{output}"
      end
      job_id = output.lines.to_a.last.to_i.to_s
      log.puts "job_id: #{job_id}"
      {:job_id => job_id, :raw_output => output.lines.map(&:chomp).to_a }
    end

    def parse_status(line)
      if line
        status = case line.split[4]
        when /Q/
          :queued
        when /[RTE]/
          :running
        when /C/
          :finished
        else
          raise "unknown output: #{output}"
        end
      else
        status = :finished
      end
      { :status => status, :raw_output => [line] }
    end

    def status(job_id)
      cmd = "qstat #{job_id}"
      output = `#{cmd}`
      if $?.to_i == 0
        parse_status( output.lines.grep(/^\s*#{job_id}/).last )
      else
        {:status => :finished, :raw_output => output}
      end
    end

    def multiple_status(job_id_list)
      cmd = "qstat"
      output_list = `#{cmd}`.split(/\R/)

      results = {}
      job_id_list.each do |job_id|
        results[job_id] = parse_status(output_list.grep(/^\s*#{job_id}/).last)
      end
      results
    end

    def all_status
      cmd = "qstat && pbsnodes -a"
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

