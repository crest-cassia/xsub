require_relative '../support/shared_examples_for_scheduler'

RSpec.describe Xsub::SR16000 do

  it_behaves_like "Scheduler::CONSTANTS"


  valid_params = [
    {"mpi_procs" => 64, "omp_threads" => 1, "job_class" => "c"}
  ]
  invalid_params = [
    [
      {"mpi_procs" => 1, "omp_threads" => 1, "job_class" => "c"},
      /mpi_procs must be a multiple of/
    ]
  ]

  it_behaves_like "Scheduler#validate_parameters", valid_params, invalid_params

  submit_test_ok_cases = [
    {
      command: "cd #{Dir.pwd}/work_test && llsubmit #{Dir.pwd}/job.sh",
      out: <<EOS,
KBGT60003-I Budget function authenticated bu0701. bu0701 is not assigned account number.
llsubmit: The job "htcf02c01p02.134491" has been submitted.
EOS
      rc: 0,
      job_id: "htcf02c01p02.134491"
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
      job_id: "htcf02c01p02.134491",
      command: "llq htcf02c01p02.134491",
      out: <<EOS,
Id                       Owner      Submitted   ST PRI Class        Running On 
------------------------ ---------- ----------- -- --- ------------ -----------
htcf02c01p02.134491.0    bu0701      8/15 14:37 I  50  c                       

1 job step(s) in query, 1 waiting, 0 pending, 0 running, 0 held, 0 preempted
EOS
      rc: 0,
      status: :queued
    },
    {
      job_id: "htcf02c01p02.134491",
      command: "llq htcf02c01p02.134491",
      out: <<EOS,
Id                       Owner      Submitted   ST PRI Class        Running On 
------------------------ ---------- ----------- -- --- ------------ -----------
htcf02c01p02.134491.0    bu0701      8/15 14:37 R  50  c                       

1 job step(s) in query, 0 waiting, 0 pending, 1 running, 0 held, 0 preempted
EOS
      rc: 0,
      status: :running
    },
    {
      job_id: "htcf02c01p02.134491",
      command: "llq htcf02c01p02.134491",
      out: <<EOS,
EOS
      rc: 153,
      status: :finished
    }
  ]

  it_behaves_like "Scheduler#status", status_test_cases

  it_behaves_like "Scheduler#all_status", "llq"

  it_behaves_like "Scheduler#delete", "llcancel"
end

