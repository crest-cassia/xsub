require 'date'
require File.expand_path(File.dirname(__FILE__)+'/../scheduler')

module Xsub

  class NqsII < Scheduler

    TEMPLATE = <<EOS
#!/bin/bash -x
#PBS -N <%= name_job %>
#PBS --group=<%= group %>
#PBS -q <%= queue %>
#PBS -b <%= mpi_procs.to_i*omp_threads.to_i/ppn.to_i %>
#PBS -l cpunum_job=<%= cpunum_job %>
#PBS -l gpunum_job=<%= gpunum_job %>
#PBS -l elapstim_req=<%= walltime %>
#PBS -v OMP_NUM_THREADS=<%= omp_threads.to_i %>
#PBS -p <%= priority %>
cd <%= File.expand_path(_work_dir) %>
LANG=C
. <%= _job_file %>
EOS

    PARAMETERS = {
      "name_job" => { :description => "name of job", :default => "oacis_job", :format => '$'},
      "group" => { :description => "request group", :default => "g-nairobi", :format => '$'},
      "cpunum_job" => { :description => "core numbers of 1 node CPU (1~40)", :default => 1, :format => '^[1-9]\d*$'},
      "gpunum_job" => { :description => "core numbers of 1 node GPU (0~8)", :default => 0, :format => '^[0-9]\d*$'},
      "queue" =>  { :description => "request queue", :default => "cq", :format => '$'},
      "mpi_procs" => { :description => "MPI process", :default => 1, :format => '^[1-9]\d*$'},
      "omp_threads" => { :description => "OMP threads", :default => 1, :format => '^[1-9]\d*$'},
      "ppn" => { :description => "Process per nodes", :default => 1, :format => '^[1-9]\d*$'},
      "priority" => { :description => "priority", :default => 1, :format => '^[1-9]\d*$'},
      "walltime" => { :description => "Limit on elapsed time", :default => "0:03:00", :format => '^\d+:\d{2}:\d{2}$'}
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
      cmd = "qsub #{File.expand_path(script_path)} -v PBS_O_WORKDIR=#{File.expand_path(work_dir)} -d #{File.expand_path(work_dir)}/request.log -o #{File.expand_path(log_dir)}/execute.log -e #{File.expand_path(log_dir)}/error.log"
      log.puts "cmd: #{cmd}", "time: #{DateTime.now}"
      output = `#{cmd}`
      unless $?.to_i == 0
        log.puts "rc is not zero: #{output}"
        raise "rc is not zero: #{output}, #{File.expand_path(work_dir)}"
      end
      job_id = output.lines.to_a.last.split[1]
      log.puts "job_id: #{job_id}"
      {:job_id => job_id, :raw_output => output.lines.map(&:chomp).to_a }
    end

    def status(job_id)
      cmd = "qstat #{job_id}"
      output = `#{cmd}`
      if $?.to_i == 0
        # RequestID       ReqName  UserName Queue     Pri STT S   Memory      CPU   Elapse R H M Jobs
        # --------------- -------- -------- -------- ---- --- - -------- -------- -------- - - - ----
        # 12345.bsv0xx    yyy_job  z_user   cq          0 RUN -    1.00G     0.10        4 Y Y Y    1
        status = case output.lines.to_a.last.split[5]
        when /QUE|GQD/
          :queued
        when /RUN|TRS|POR|PRR/
          :running
        when /EXT/ #exiting
          :running
        when /exist/ #Batch Request: 12345.bsv0xx does not exist on bsv0xx.
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
      cmd = "qstat -Q"
      #cmd = "qstat -St"
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

