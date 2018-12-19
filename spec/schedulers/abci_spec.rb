require File.join( File.dirname(__FILE__), '../support/shared_examples_for_scheduler')

RSpec.describe Xsub::Abci do

  it_behaves_like "Scheduler::CONSTANTS"


  valid_params = [
    {"mpi_procs" => 4, "omp_threads" => 8, "ppn" => 8}
  ]
  invalid_params = [
  ]

  it_behaves_like "Scheduler#validate_parameters", valid_params, invalid_params

  submit_test_ok_cases = [
    {
      :parameters => {"group" => "g1234", "name_job" => "my_job", "resource_type_num" => "rt_F=1"},
      :command => "cd #{Dir.pwd}/work_test && qsub -g g1234 -o #{Dir.pwd}/log_test/execute.log -e #{Dir.pwd}/log_test/error.log #{Dir.pwd}/job.sh",
      :out => "job submitted 19352",
      :rc => 0,
      :job_id => "19352",
    }
  ]
  submit_test_ng_cases = [
    {
      :parameters => {"group" => "g1234", "name_job" => "my_job", "resource_type_num" => "rt_F=1"},
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
      :command => "qstat | grep 19352",
      :out => <<EOS,
19352.localhost           job.sh           test_user              0 qw batch
EOS
      :rc => 0,
      :status => :queued
    },
    {
      :job_id => "19352",
      :command => "qstat | grep 19352",
      :out => <<EOS,
19352.localhost           job.sh           test_user              0 r batch
EOS
      :rc => 0,
      :status => :running
    },
    {
      :job_id => "19352",
      :command => "qstat | grep 19352",
      :out => <<EOS,
19352.localhost           job.sh           test_user              0 hqw batch
EOS
      :rc => 0,
      :status => :queued
    },
    {
      :job_id => "19352",
      :command => "qstat | grep 19352",
      :out => <<EOS,
EOS
      :rc => 153,
      :status => :finished
    },
    {
      :job_id => "19352",
      :command => "qstat | grep 19352",
      :out => <<EOS,
19352.localhost           ...b0000_xsub.sh test_user       02:13:28 e batch
EOS
      :rc => 0,
      :status => :finished
    }
    ]

  it_behaves_like "Scheduler#status", status_test_cases

  it_behaves_like "Scheduler#all_status", "qstat -g c"

  it_behaves_like "Scheduler#delete", "qdel"
end

