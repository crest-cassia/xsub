require 'date'
require File.expand_path(File.dirname(__FILE__)+'/../scheduler')

module Xsub

  class FX700 < Scheduler

    TEMPLATE = <<EOS
#!/bin/bash
#SBATCH -p <%= queue %>
#SBATCH -N <%= num_nodes.to_i %>
#SBATCH --ntasks-per-node=<%= mpi_procs/num_nodes.to_i %>
#SBATCH -c <%= omp_threads %>
#SBATCH --chdir=<%= _work_dir %>
#SBATCH --time=<%= walltime %>

LANG=C
module load PrgEnv-intel module load impi

. <%= _job_file %>
EOS

    QUEUE_TYPES = %w(fx700 cs500 apollo70 r340)

    PARAMETERS = {
      "mpi_procs" => { :description => "MPI process", :default => 1, :format => '^[1-9]\d*$'},
      "omp_threads" => { :description => "OMP threads", :default => 1, :format => '^[1-9]\d*$'},
      "queue" => { :description => "Job queue", :default => QUEUE_TYPES.first, :format => "^(#{QUEUE_TYPES.join('|')})$"},
      "num_nodes" => { :description => "Number of nodes", :default => 1, :format => '^[1-9]\d*$'},
      "walltime" => { :description => "Limit on elapsed time", :default => "1:00:00", :format => '^\d+:\d{2}:\d{2}$'}
    }

    def validate_parameters(prm)
      mpi = prm["mpi_procs"].to_i
      omp = prm["omp_threads"].to_i
      num_nodes = prm["num_nodes"].to_i
      unless mpi%num_nodes == 0
        raise "mpi_procs must be a multiple of num_nodes"
      end
    end

    def submit_job(script_path, work_dir, log_dir, log, parameters)
      cmd = "sbatch -o #{File.expand_path(log_dir)}/stdout.%j -e #{File.expand_path(log_dir)}/stderr.%j #{File.expand_path(script_path)}"
      log.puts "cmd: #{cmd}", "time: #{DateTime.now}"
      output = `#{cmd}`
      unless $?.to_i == 0
        log.puts "rc is not zero: #{output}"
        raise "rc is not zero: #{output}"
      end
      if output =~ /Submitted batch job (\d+)/
        job_id = $1
        log.puts "job_id: #{job_id}"
        {:job_id => job_id, :raw_output => output.lines.map(&:chomp).to_a }
      else
        raise "unknown output format: #{output}"
      end
    end

    def status(job_id)
      cmd = "squeue --job #{job_id}"
      output = `#{cmd}`
      unless $?.to_i == 0
        raise "rc is not zero. rc: #{$?.to_i}"
      end

      last_line = output.lines.to_a.last
      if last_line =~ /^Invalid job id/
        status = :finished
      else
        status = case last_line.split[4]
        when /^(PD|CF)$/
          :queued
        when /^(R|S)$/
          :running
        when /^(CA|CD|CG|F|NF|PR|TO)$/
          :finished
        when /ST/
          :finished
          # sometimes, fjstat returns empty string for status.
          # in such a case, uiud.... is obtained by `last_line.split[4]`
        else
          raise "unknown output: #{output}"
        end
      end
      { :status => status, :raw_output => output.lines.map(&:chomp).to_a }
    end

    def all_status
      cmd = "squeue"
      output = `#{cmd}`
      output
    end

    def delete(job_id)
      cmd = "scancel #{job_id}"
      output = `#{cmd}`
      raise "failed to delete job: #{job_id}" unless $?.to_i == 0
      output
    end
  end
end

