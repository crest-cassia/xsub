require_relative '../support/shared_examples_for_scheduler'

RSpec.describe Xsub::SLURM_FOCUS do

  it_behaves_like "Scheduler::CONSTANTS"


  valid_params = [
    {"mpi_procs" => 8, "omp_threads" => 5, "queue" => "d024h", "num_nodes" => 2}
  ]
  invalid_params = [
    [
      {"mpi_procs" => 8, "omp_threads" => 5, "queue" => "d024h", "num_nodes" => 3},
      /mpi_procs must be a multiple of num_nodes/
    ]
  ]

  it_behaves_like "Scheduler#validate_parameters", valid_params, invalid_params

  submit_test_ok_cases = [
    {
      command: "sbatch #{Dir.pwd}/job.sh -o #{Dir.pwd}/log_test/stdout.%j -e #{Dir.pwd}/log_test/stderr.%j",
      out: "1234",
      rc: 0,
      job_id: "1234"
    }
  ]
  submit_test_ng_cases = [
    {
      command: nil,
      out: nil,
      rc: 1,
      error: /rc is not zero/
    }
  ]

  it_behaves_like "Scheduler#submit_job", submit_test_ok_cases, submit_test_ng_cases

  status_test_cases = [
    {
      job_id: "1234",
      command: "squeue 1234",
      out: <<EOS,
      JOBID PARTITION NAME    USER    ST TIME NODES NODELIST(REASON) 
      1234  d024h     testrun u987654 PD 0:00    60 (Resources)
EOS
      rc: 0,
      status: :queued
    },
    {
      job_id: "1234",
      command: "squeue 1234",
      out: <<EOS,
      JOBID PARTITION NAME    USER    ST TIME NODES NODELIST(REASON) 
      1234  d024h     testrun u987654 R  5:02    60 d[007-066]
EOS
      rc: 0,
      status: :running
    },
    {
      job_id: "1234",
      command: "squeue 1234",
      out: <<EOS,
      JOBID PARTITION NAME    USER    ST TIME NODES NODELIST(REASON) 
      1234  d024h     testrun u987654 CD 5:02    60 d[007-066]
EOS
      rc: 0,
      status: :finished
    },
    {
      job_id: "1234",
      command: "squeue 1234",
      out: <<EOS,
      JOBID PARTITION NAME    USER    ST TIME NODES NODELIST(REASON) 
EOS
      rc: 153,
      status: :finished
    }
  ]

  it_behaves_like "Scheduler#status", status_test_cases

  it_behaves_like "Scheduler#all_status", "squeues && freenodes"

  it_behaves_like "Scheduler#delete", "scancel"
end

