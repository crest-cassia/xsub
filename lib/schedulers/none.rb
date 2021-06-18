require File.expand_path(File.dirname(__FILE__)+'/../scheduler')

module Xsub

  class None < Scheduler

    TEMPLATE = <<EOS
. <%= _job_file %>
EOS

    PARAMETERS = {
      "mpi_procs" => { :description => "MPI process", :default => 1, :format => '^[1-9]\d*$'},
      "omp_threads" => { :description => "OMP threads", :default => 1, :format => '^[1-9]\d*$'}
    }

    def validate_parameters(params)
    end

    def submit_job(script_path, work_dir, log_dir, log, parameters)
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
      {:job_id => psid, :raw_output => output.lines.map(&:chomp).to_a}
    end

    def status(job_id)
      cmd = "ps -p #{job_id}"
      output = `#{cmd}`
      status = $?.to_i == 0 ? :running : :finished
      { :status => status, :raw_output => output.lines.map(&:chomp).to_a }
    end

    def all_status
      cmd = "ps uxr | head -n 10"
      output = `#{cmd}`
      output
    end

    def list_related_pids(pid)
      pid_list = []
      system("kill -0 #{pid}")
      if $?.to_i == 0 then
        p "ps --ppid #{pid} -o \"pid=\""
        `ps --ppid #{pid} -o "pid="`.lines.each { |p|
          pid_list.concat(list_related_pids(p.strip))
        }
        pid_list << pid.to_i
      end
      pid_list
    end

    def delete(job_id)
      pid_list = list_related_pids job_id
      if pid_list.length > 0
        pids = pid_list.join(' ')
        cmd = "kill -KILL #{pids}"
        system(cmd)
        output = "process is killed"
      else
        raise "Process is not found"
      end
      output
    end
  end
end
