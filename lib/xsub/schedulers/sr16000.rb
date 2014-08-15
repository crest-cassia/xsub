module Xsub

  class SchedulerSR16000_FlatMPI_SMT < Base

    TEMPLATE = <<EOS
#!/bin/csh -f
#@class = <%= job_class %>
#@job_type = parallel
#@network.MPI=sn_single,,US,,instances=1
#@bulkxfer=yes
#@node = <%= mpi_procs / 64 %>
#@tasks_per_node = 64
#@resources = ConsumableCpus(1)
#@output = $(host).$(jobid).stdout
#@error = $(host).$(jobid).stderr
#@queue

unlimit
setenv MEMORY_AFFINITY MCM
setenv MP_SHARED_MEMORY no
setenv HF_PRUNST_THREADNUM 1
setenv XLSMPOPTS "spins=0:yields=0:parthds=1"

. <%= job_file %>
EOS

    PARAMETERS = {
      "mpi_procs" => { description: "MPI process", default: 1, format: '^[1-9]\d*$'},
      "omp_threads" => { description: "OMP threads", default: 1, format: '^[1-9]\d*$'},
      "job_class" => { description: "Job class", default: "c"},
    }

    def validate_parameters(prm)
      mpi = prm["mpi_procs"].to_i
      omp = prm["omp_threads"].to_i
      unless mpi >= 1 and omp >= 1
        raise "mpi_procs and omp_threads must be larger than or equal to 1"
      end
      unless mpi % 64 == 0
        raise "mpi_procs must be a multiple of 64"
      end
    end

    def submit_job(script_path)
      FileUtils.mkdir_p(@work_dir)
      FileUtils.mkdir_p(@log_dir)

      cmd = "cd #{File.expand_path(@work_dir)} && llsubmit #{File.expand_path(script_path)}"
      @logger.info "cmd: #{cmd}"
      output = `#{cmd}`
      raise "rc is not zero: #{output}" unless $?.to_i == 0
      job_id = output.lines.to_a.last
      @logger.info "job_id: #{job_id}"
      {job_id: job_id, raw_output: output.lines.map(&:chomp).to_a }
    end

    def status(job_id)
      cmd = "llstatus #{job_id}"
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
      cmd = "llstatus"
      output = `#{cmd}`
      { raw_output: output.lines.map(&:chomp).to_a }
    end

    def delete(job_id)
      cmd = "llcancel #{job_id}"
      output = `#{cmd}`
      output = "pjdel failed: rc=#{$?.to_i}" unless $?.to_i == 0
      {raw_output: output.lines.map(&:chomp).to_a }
    end
  end
end
