require 'date'
require_relative '../scheduler'

module Xsub

  class SLURM_FOCUS < Scheduler

    TEMPLATE = <<EOS
#!/bin/bash
#SBATCH -p <%= queue %>
#SBATCH -N <%= num_nodes %>
#SBATCH --ntasks-per-node=<%= mpi_procs/num_nodes %>
#SBATCH -c <%= omp_threads %>
#SBATCH --work_dir <%= _work_dir %>

LANG=C
module load PrgEnv-intel module load impi

. <%= _job_file %>
EOS

    QUEUE_TYPES = %w(a024h a096h b024h b096h c024h c096h c006m d006h d012h d024h d072h e024h e072h g006m)

    PARAMETERS = {
      "mpi_procs" => { description: "MPI process", default: 1, format: '^[1-9]\d*$'},
      "omp_threads" => { description: "OMP threads", default: 1, format: '^[1-9]\d*$'},
      "queue" => { description: "Job queue", default: QUEUE_TYPES.first, format: "^(#{QUEUE_TYPES.join('|')})$" },
      "num_nodes" => { description: "Number of nodes", default: 1, format: '^[1-9]\d*$'}
    }

    def validate_parameters(prm)
      mpi = prm["mpi_procs"].to_i
      omp = prm["omp_threads"].to_i
      num_nodes = prm["num_nodes"].to_i
      unless mpi%num_nodes == 0
        raise "mpi_procs must be a multiple of num_nodes"
      end
    end

    def submit_job(script_path, work_dir, log_dir, log)
      cmd = "sbatch #{File.expand_path(script_path)} -o #{File.expand_path(log_dir)}/stdout.%j -e #{File.expand_path(log_dir)}/stderr.%j"
      log.puts "cmd: #{cmd}", "time: #{DateTime.now}"
      output = `#{cmd}`
      unless $?.to_i == 0
        log.puts "rc is not zero: #{output}"
        raise "rc is not zero: #{output}"
      end
      ## TODO : parse output of sbatch command
      job_id = output.lines.to_a.last.to_i.to_s
      log.puts "job_id: #{job_id}"
      {job_id: job_id, raw_output: output.lines.map(&:chomp).to_a }
    end

    def status(job_id)
      cmd = "squeue #{job_id}"
      output = `#{cmd}`
      if $?.to_i == 0
        status = case output.lines.to_a.last.split[4]
        when /^(CF|PD)$/
          :queued
        when /^(CG|R|S)$/
          :running
        when /^(CA|CD|F|NF|PR|TO)$/
          :finished
        else
          raise "unknown output: #{output}"
        end
      else
        # TODO : check the specification of unknown job_id
        status = :finished
      end
      { status: status, raw_output: output.lines.map(&:chomp).to_a }
    end

    def all_status
      cmd = "squeues && freenodes"
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

