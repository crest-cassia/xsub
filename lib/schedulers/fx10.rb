module Xsub

  class Fx10 < Scheduler

    TEMPLATE = <<EOS
#!/bin/bash -x
#
#PJM --rsc-list "node=<%= node %>"
#PJM --rsc-list "elapse=<%= elapse %>"
#PJM --mpi "shape=<%= shape %>"
#PJM --mpi "proc=<%= mpi_procs %>"
#PJM -s
LANG=C
. /work/system/Env_base
. <%= _job_file %>
EOS

    PARAMETERS = {
      "mpi_procs" => { description: "MPI process", default: 1, format: '^[1-9]\d*$'},
      "omp_threads" => { description: "OMP threads", default: 1, format: '^[1-9]\d*$'},
      "elapse" => { description: "Limit on elapsed time", default: "1:00:00", format: '^\d+:\d{2}:\d{2}$'},
      "node" => { description: "Nodes", default: "1", format: '^\d+(x\d+){0,2}$'},
      "shape" => { description: "Shape", default: "1", format: '^\d+(x\d+){0,2}$'}
    }

    def validate_parameters(prm)
      mpi = prm["mpi_procs"].to_i
      omp = prm["omp_threads"].to_i
      unless mpi >= 1 and omp >= 1
        raise "mpi_procs and omp_threads must be larger than or equal to 1"
      end
      tmp_node = prm['node'].split("x")
      tmp_shape = prm['shape'].split("x")
      unless tmp_node.length == tmp_shape.length
        raise "node and shape must be same format like node=>4x3, shape=>1x1"
      end
      tmp_node.each_with_index do |n, i|
        unless n >= tmp_shape[i]
          raise "each # in shape must be smaller than the one of node"
        end
      end
      max_proc = tmp_shape.map {|s| s.to_i }.inject(:*)*8
      unless mpi <= max_proc
        raise "mpi_porc must be less than or equal to #{max_proc}"
      end
    end

    def submit_job(script_path, work_dir, log_dir)
      stdout_path = File.join( File.expand_path(log_dir), '%j.o.txt')
      stderr_path = File.join( File.expand_path(log_dir), '%j.e.txt')
      job_stat_path = File.join( File.expand_path(log_dir), '%j.i.txt')
      log = File.open( File.join(log_dir, 'xsub.log'), 'w' )

      cmd = "cd #{File.expand_path(work_dir)} && pjsub #{File.expand_path(script_path)} -o #{stdout_path} -e #{stderr_path} --spath #{job_stat_path}"
      log.puts "cmd: #{cmd}"
      log.puts "date: #{DateTime.now}"
      output = `#{cmd}`
      unless $?.to_i == 0
        log.puts "rc is not zero: #{output}"
        raise "rc is not zero: #{output}"
      end
      if output.lines.to_a.last =~ /Job (\d+) submitted/
        job_id = $1
        log.puts "job_id: #{job_id}"
      else
        log.puts "failed to get job_id: #{output}"
        raise "failed to get job_id: #{output}"
      end
      log.flush && log.close
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
      output
    end

    def delete(job_id)
      cmd = "pjdel #{job_id}"
      output = `#{cmd}`
      raise "pjdel failed: rc=#{$?.to_i}" unless $?.to_i == 0
      output
    end
  end
end
