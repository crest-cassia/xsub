module Xsub

  class SchedulerFx10 < Base

    TEMPLATE = <<EOS
#!/bin/bash
#
#PJM --rsc-list "node=<%= ((mpi_procs*omp_threads)/8.0).ceil %>"
#PJM --rsc-list "elapse=<%= elapse %>"
#PJM --mpi "shape=<%= ((mpi_procs*omp_threads)/8.0).ceil %>"
#PJM --mpi "proc=<%= mpi_procs %>"
#PJM -s
LANG=C
. /work/system/Env_base
. <%= job_file %>
EOS

    PARAMETERS = {
      "mpi_procs" => { description: "MPI process", default: 1},
      "omp_threads" => { description: "OMP threads", default: 1},
      "elapse" => { description: "Limit on elapsed time", default: "1:00:00"}
    }

    def validate_parameters(prm)
      mpi = prm["mpi_procs"].to_i
      omp = prm["omp_threads"].to_i
      unless mpi >= 1 and omp >= 1
        raise "mpi_procs and omp_threads must be larger than or equal to 1"
      end
    end

    def submit_job(script_path)
      FileUtils.mkdir_p(@work_dir)
      FileUtils.mkdir_p(@log_dir)
      stdout_path = File.join( File.expand_path(@log_dir), '%j.o')
      stderr_path = File.join( File.expand_path(@log_dir), '%j.e')
      job_stat_path = File.join( File.expand_path(@log_dir), '%j.i')

      cmd = "cd #{File.expand_path(@work_dir)} && pjsub #{File.expand_path(script_path)} -o #{stdout_path} -e #{stderr_path} --spath #{job_stat_path}"
      @logger.info "cmd: #{cmd}"
      output = `#{cmd}`
      raise "rc is not zero: #{output}" unless $?.to_i == 0
      job_id = output.lines.to_a.last
      @logger.info "job_id: #{job_id}"
      {job_id: job_id, raw_output: output.lines.map(&:chomp).to_a }
    end

    def status(job_id)
      cmd = "pjstat #{job_id}"
      output = `#{cmd}`
      if $?.to_i == 0
        status = case output.lines.to_a.last.split[3]
        when /ACC|QUE/
          :queued
        when /SIN|RDY|RNA|RUN|RNO|SOT/
          :running
        when /EXT|CCL/
          :finished
        else
          :finished
        end
      else
        status = :finished
      end
      { status: status, raw_output: output.lines.map(&:chomp).to_a }
    end

    def all_status
      cmd = "pjstat"
      output = `#{cmd}`
      { raw_output: output.lines.map(&:chomp).to_a }
    end

    def delete(job_id)
      cmd = "pjdel #{job_id}"
      output = `#{cmd}`
      output = "pjdel failed: rc=#{$?.to_i}" unless $?.to_i == 0
      {raw_output: output.lines.map(&:chomp).to_a }
    end
  end
end
