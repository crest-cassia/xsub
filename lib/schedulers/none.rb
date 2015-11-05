require_relative '../scheduler'

module Xsub

  class None < Scheduler

    TEMPLATE = <<EOS
. <%= _job_file %>
EOS

    PARAMETERS = {
      "mpi_procs" => { description: "MPI process", default: 1, format: '^[1-9]\d*$'},
      "omp_threads" => { description: "OMP threads", default: 1, format: '^[1-9]\d*$'}
    }

    def validate_parameters(params)
    end

    def submit_job(script_path, work_dir, log_dir, log)
      full_path = File.expand_path(script_path)
      cmd = "nohup bash #{full_path} > /dev/null 2>&1 < /dev/null & echo $!"
      log.puts "#{cmd} is invoked"
      output = ""
      FileUtils.mkdir_p(work_dir)
      Dir.chdir(work_dir) {
        output = `#{cmd}`
        raise "rc is not zero: #{cmd}" unless $?.to_i == 0
      }
      psid = output.lines.to_a.last.to_i.to_s
      log.puts "process id: #{psid}"
      {job_id: psid, raw_output: output.lines.map(&:chomp).to_a}
    end

    def status(job_id)
      cmd = "ps -p #{job_id}"
      output = `#{cmd}`
      status = $?.to_i == 0 ? :running : :finished
      { status: status, raw_output: output.lines.map(&:chomp).to_a }
    end

    def all_status
      cmd = "ps uxr | head -n 10"
      output = `#{cmd}`
      output
    end

    def delete(job_id)
      pgid = `ps -p #{job_id} -o "pgid"`.lines.to_a.last.to_i.to_s
      if $?.to_i == 0
        cmd = "kill -TERM -#{pgid}"
        system(cmd)
        raise "kill command failed: #{cmd}" unless $?.to_i == 0
        output = "process is killed"
      else
        raise "Process is not found"
      end
      output
    end
  end
end
