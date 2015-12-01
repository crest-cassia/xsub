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
      command: "fjsub -o #{Dir.pwd}/log_test/stdout.%j -e #{Dir.pwd}/log_test/stderr.%j #{Dir.pwd}/job.sh",
      out: "Submitted batch job 532271\n",
      rc: 0,
      job_id: "532271"
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
      job_id: "532271",
      command: "fjstat 532271",
      out: <<EOS,
    QUEUED    RUNNING       HOLD     ERROR     TOTAL
         1          0          0         0         1
   s     1          0          0         0         1
  JOB_ID        JOB_NAME  MD   ST         USER      START_DATE  ELAPSE_LIM  NODE_REQUIRE
  547608 hello_hybrid     NM  QUE     uiud0019             N/A  0000:06:00             2
EOS
      rc: 0,
      status: :queued
    },
    {
      job_id: "532271",
      command: "fjstat 532271",
      out: <<EOS,
    QUEUED    RUNNING       HOLD     ERROR     TOTAL
         1          0          0         0         1
   s     1          0          0         0         1
  JOB_ID        JOB_NAME  MD   ST         USER      START_DATE  ELAPSE_LIM  NODE_REQUIRE
  547608 hello_hybrid     NM  RUN     uiud0019             N/A  0000:06:00             2
EOS
      rc: 0,
      status: :running
    },
    {
      job_id: "532271",
      command: "fjstat 532271",
      out: <<EOS,
    QUEUED    RUNNING       HOLD     ERROR     TOTAL
         1          0          0         0         1
   s     1          0          0         0         1
  JOB_ID        JOB_NAME  MD   ST         USER      START_DATE  ELAPSE_LIM  NODE_REQUIRE
  547608 hello_hybrid     NM  EXT     uiud0019             N/A  0000:06:00             2
EOS
      rc: 0,
      status: :finished
    },
    {
      job_id: "532271",
      command: "fjstat 532271",
      out: <<EOS,
    QUEUED    RUNNING       HOLD     ERROR     TOTAL
         0          0          0         0         1
   s     0          0          0         0         1
  JOB_ID        JOB_NAME  MD   ST         USER      START_DATE  ELAPSE_LIM  NODE_REQUIRE
  547666 sleep5_xsub3.sh  NM          uiud0019  11/28 15:01:52  0000:06:00
EOS
      rc: 0,
      status: :finished
    },
    {
      job_id: "532271",
      command: "fjstat 532271",
      out: <<EOS,
Invalid job ID is specified : 532271
EOS
      rc: 0,
      status: :finished
    }
  ]

  it_behaves_like "Scheduler#status", status_test_cases

  it_behaves_like "Scheduler#all_status", "fjstat && squeues"

  it_behaves_like "Scheduler#delete", "fjdel"
end

