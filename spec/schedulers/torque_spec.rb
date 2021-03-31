require File.join( File.dirname(__FILE__), '../support/shared_examples_for_scheduler')

RSpec.describe Xsub::Torque do

  it_behaves_like "Scheduler::CONSTANTS"


  valid_params = [
    {"mpi_procs" => 4, "omp_threads" => 8, "ppn" => 8}
  ]
  invalid_params = [
    [
      {"mpi_procs" => 4, "omp_threads" => 8, "ppn" => 6},
      /must be a multiple of ppn/
    ]
  ]

  it_behaves_like "Scheduler#validate_parameters", valid_params, invalid_params

  submit_test_ok_cases = [
    {
      :command => "qsub #{Dir.pwd}/job.sh -d #{Dir.pwd}/work_test -o #{Dir.pwd}/log_test -e #{Dir.pwd}/log_test",
      :out => "19352.localhost",
      :rc => 0,
      :job_id => "19352"
    }
  ]
  submit_test_ng_cases = [
    {
      :command => nil,
      :out => nil,
      :rc => 1,
      :error => /rc is not zero/
    }
  ]

  it_behaves_like "Scheduler#submit_job", submit_test_ok_cases, submit_test_ng_cases


    status_test_cases = [
    {
      :job_id => "19352",
      :command => "qstat 19352",
      :out => <<EOS,
Job id                    Name             User            Time Use S Queue
------------------------- ---------------- --------------- -------- - -----
19352.localhost           job.sh           test_user              0 Q batch
EOS
      :rc => 0,
      :status => :queued
    },
    {
      :job_id => "19352",
      :command => "qstat 19352",
      :out => <<EOS,
Job id                    Name             User            Time Use S Queue
------------------------- ---------------- --------------- -------- - -----
19352.localhost           job.sh           test_user              0 R batch
EOS
      :rc => 0,
      :status => :running
    },
    {
      :job_id => "19352",
      :command => "qstat 19352",
      :out => <<EOS,
Job id                    Name             User            Time Use S Queue
------------------------- ---------------- --------------- -------- - -----
19352.localhost           job.sh           test_user              0 C batch
EOS
      :rc => 0,
      :status => :finished
    },
    {
      :job_id => "19352",
      :command => "qstat 19352",
      :out => <<EOS,
EOS
      :rc => 153,
      :status => :finished
    },
    {
      :job_id => "19352",
      :command => "qstat 19352",
      :out => <<EOS,
Job ID                    Name             User            Time Use S Queue
------------------------- ---------------- --------------- -------- - -----
19352.localhost           ...b0000_xsub.sh test_user       02:13:28 E batch
EOS
      :rc => 0,
      :status => :running
    }
    ]

  it_behaves_like "Scheduler#status", status_test_cases

  multiple_status_test_cases = [
    {
      :job_ids => ["0.master", "1.master","2.master"],
      :commands => {
        "qstat" => [0, <<~EOS]
            Job ID                    Name             User            Time Use S Queue
            ------------------------- ---------------- --------------- -------- - -----
            0.master                   sleep.sh         batchuser              0 R batch
            1.master                   sleep.sh         batchuser              0 Q batch
          EOS
      },
      :expected => {
        "0.master" => {:status => :running},
        "1.master" => {:status => :queued},
        "2.master" => {:status => :finished}
      }
    }
  ]

  it_behaves_like "Scheduler#multiple_status", multiple_status_test_cases

  it_behaves_like "Scheduler#all_status", "qstat && pbsnodes -a"

  it_behaves_like "Scheduler#delete", "qdel"
end

