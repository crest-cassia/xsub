module AnyScheduler

  class SchedulerTorque < Base

    TEMPLATE = <<EOS
#!/bin/bash
LANG=C
#PBS -l nodes=<%= mpi_procs*omp_threads/ppn %>:ppn=<%= ppn %>
#PBS -l walltime=<%= elapsed %>
. <%= job_file %>
EOS

    PARAMETERS = {
      "mpi_procs" => { description: "MPI process", default: 1},
      "omp_threads" => { description: "OMP threads", default: 1},
      "ppn" => { description: "Process per nodes", default: 1},
      "elapsed" => { description: "Limit on elapsed time", default: "1:00:00"}
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

    def submit_job(script_path)
      cmd = "nohup bash #{script_path} > /dev/null 2>&1 < /dev/null & echo $!"
      output = `#{cmd}`
      raise "rc is not zero: #{output}" unless $?.to_i == 0
      psid = output.lines.last.to_i
      {job_id: psid, output: output}
    end
  end
end
