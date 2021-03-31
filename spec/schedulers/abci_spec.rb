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
      :out => "Your job 19352 (\"my_job\") has been submitted",
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
      :error => /return-code is not zero/
    }
  ]

  it_behaves_like "Scheduler#submit_job", submit_test_ok_cases, submit_test_ng_cases

  status_test_cases = [
    {
      :job_id => "19352",
      :command => "qstat | grep '^ *19352'",
      :out => <<~EOS,
        19352 0.00000 job.sh    u1234   qw    07/03/2020 20:18:38
        EOS
      :rc => 0,
      :status => :queued
    },
    {
      :job_id => "19352",
      :command => "qstat | grep '^ *19352'",
      :out => <<~EOS,
        19352 0.25586 job.sh    u1234   r     07/03/2020 20:18:38
        EOS
      :rc => 0,
      :status => :running
    },
    {
      :job_id => "19352",
      :command => "qstat | grep '^ *19352'",
      :out => <<~EOS,
        19352 0.00000 job.sh    u1234   hqw   07/03/2020 20:18:38
        EOS
      :rc => 0,
      :status => :queued
    },
    {
      :job_id => "19352",
      :command => "qstat | grep '^ *19352'",
      :out => <<~EOS,
        EOS
      :rc => 153,
      :status => :finished
    },
    {
      :job_id => "19352",
      :command => "qstat | grep '^ *19352'",
      :out => <<~EOS,
        19352 0.00000 job.sh    u1234   Eqw   07/03/2020 20:18:38
        EOS
      :rc => 0,
      :status => :finished
    }
  ]

  it_behaves_like "Scheduler#status", status_test_cases

  multiple_status_test_cases = [
    {
      :job_ids => ["19352", "19353", "19354"],
      :commands => {"qstat" => [0,<<~EOS],
        19352 0.00000 job.sh    u1234   qw    07/03/2020 20:18:38
        19353 0.25586 job.sh    u1234   r     07/03/2020 20:18:38
        19354 0.00000 job.sh    u1234   Eqw   07/03/2020 20:18:38
        EOS
      },
      :expected => {
        "19352" => {:raw_output => ["19352 0.00000 job.sh    u1234   qw    07/03/2020 20:18:38"], :status => :queued},
        "19353" => {:raw_output => ["19353 0.25586 job.sh    u1234   r     07/03/2020 20:18:38"], :status => :running},
        "19354" => {:raw_output => ["19354 0.00000 job.sh    u1234   Eqw   07/03/2020 20:18:38"], :status => :finished}
      }
    }
  ]

  it_behaves_like "Scheduler#multiple_status", multiple_status_test_cases

  it_behaves_like "Scheduler#all_status", "qstat -g c"

  it_behaves_like "Scheduler#delete", "qdel"
end

