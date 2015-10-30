require 'stringio'
require_relative '../support/shared_examples_for_scheduler'

RSpec.describe Xsub::K do

  it_behaves_like "Scheduler::CONSTANTS"


  valid_params = [
    {"mpi_procs" => 32,"omp_threads" => 8,"elapse"=>"2:00:00",
     "node" => "4x4x2", "shape" => "4x4x2"},
    {"mpi_procs" => 32,"omp_threads" => 1,"elapse"=>"2:00:00",
     "node" => "4", "shape" => "4"}
  ]
  invalid_params = [
    [
      {"mpi_procs" => 32,"omp_threads" => 8,"elapse"=>"2:00:00",
       "node" => "4x4x2", "shape" => "4x8"},
      /node and shape must be/
    ],
    [
      {"mpi_procs" => 32,"omp_threads" => 8,"elapse"=>"2:00:00",
       "node" => "4x4x2", "shape" => "4x6x1"},
      /shape must be smaller than/
    ]
  ]

  it_behaves_like "Scheduler#validate_parameters", valid_params, invalid_params


  submit_test_ok_cases = [
    {
      command: "cd #{Dir.pwd}/work_test && pjsub #{Dir.pwd}/job.sh -o #{Dir.pwd}/log_test/%j.o.txt -e #{Dir.pwd}/log_test/%j.e.txt --spath #{Dir.pwd}/log_test/%j.i.txt < /dev/null",
      out: "[INFO] PJM 0000 pjsub Job 112109 submitted.",
      rc: 0,
      job_id: "112109"
    }
  ]
  submit_test_ng_cases = [
    {
      command: nil,   # do not check command
      out: <<EOS,
[ERR.] PJM 0007 pjsub Staging option error (3)
Refer to the staging information file. (J5333b14881e31ebcd2000001.sh.s2366652)
EOS
      rc: 0,
      error: /staging option error/
    },
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
      job_id: "112111",
      command: "pjstat 112111",
      out: <<EOS,
        ACCEPT QUEUED  STGIN  READY RUNING RUNOUT STGOUT   HOLD  ERROR   TOTAL
       0      0      0      0      1      0      0      0      0       1
s      0      0      0      0      1      0      0      0      0       1

JOB_ID     JOB_NAME   MD ST  USER     START_DATE      ELAPSE_LIM NODE_REQUIRE
112111     test.sh    NM QUE test     10/29 18:42:44  0024:00:00 1
EOS
      rc: 0,
      status: :queued
    },
    {
      job_id: "112111",
      command: "pjstat 112111",
      out: <<EOS,
  ACCEPT QUEUED  STGIN  READY RUNING RUNOUT STGOUT   HOLD  ERROR   TOTAL
       0      0      0      0      1      0      0      0      0       1
s      0      0      0      0      1      0      0      0      0       1

JOB_ID     JOB_NAME   MD ST  USER     START_DATE      ELAPSE_LIM NODE_REQUIRE
112111     test.sh    NM RUN test     10/29 18:42:44  0024:00:00 1
EOS
      rc: 0,
      status: :running
    },
    {
      job_id: "112111",
      command: "pjstat 112111",
      out: <<EOS,
  ACCEPT QUEUED  STGIN  READY RUNING RUNOUT STGOUT   HOLD  ERROR   TOTAL
       0      0      0      0      1      0      0      0      0       1
s      0      0      0      0      1      0      0      0      0       1

JOB_ID     JOB_NAME   MD ST  USER     START_DATE      ELAPSE_LIM NODE_REQUIRE
112111     test.sh    NM EXT test     10/29 18:42:44  0024:00:00 1
EOS
      rc: 0,
      status: :finished
    },
    {
      job_id: "112111",
      command: "pjstat 112111",
      out: <<EOS,
  ACCEPT QUEUED  STGIN  READY RUNING RUNOUT STGOUT   HOLD  ERROR   TOTAL
       0      0      0      0      0      0      0      0      0       0
s      0      0      0      0      0      0      0      0      0       0
EOS
      rc: 0,
      status: :finished
    }
  ]

  it_behaves_like "Scheduler#status", status_test_cases

  it_behaves_like "Scheduler#all_status", "pjstat"

  describe "#delete" do

    it "cancels job by qdel command" do
      s = Xsub::K.new
      expect(s).to receive(:`).with("pjdel 112113")
      s.delete("112113")
    end
  end
end

