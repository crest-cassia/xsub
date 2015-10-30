require 'stringio'

RSpec.describe Xsub::K do

  before(:each) do
    `exit 0 > /dev/null`  # set default exit code
  end

  it "is a descendant of Scheduler" do
    expect( Xsub::Scheduler.descendants.include?(described_class) ).to be_truthy
  end

  it "has a string TEMPLATE" do
    expect( described_class::TEMPLATE ).to be_a(String)
  end

  it "has a valid format of PARAMETERS" do
    params = described_class::PARAMETERS
    params.each_pair do |key,val|
      expect( key ).to match(/^[a-z][a-zA-Z_\d]*$/)
      expect( val.keys ).to match_array [:description, :default, :format]
      expect( val[:format] ).to be_a(String)
    end
  end

  describe "#validate_parameters" do

    it "does not raise an error when valid parameters are given" do
      s = Xsub::K.new
      params = {"mpi_procs" => 32,"omp_threads" => 8,"elapse"=>"2:00:00",
                "node" => "4x4x2", "shape" => "4x4x2"}
      expect {
        s.validate_parameters(params)
      }.to_not raise_error
    end

    it "raises an error when node and shape are incompatible" do
      s = Xsub::K.new
      params = {"mpi_procs" => 32,"omp_threads" => 8,"elapse"=>"2:00:00",
                "node" => "4x4x2", "shape" => "4x8"}
      expect {
        s.validate_parameters(params)
      }.to raise_error(/node and shape must be/)
    end

    it "raises an error when shape is larger than node" do
      s = Xsub::K.new
      params = {"mpi_procs" => 32,"omp_threads" => 8,"elapse"=>"2:00:00",
                "node" => "4x4x2", "shape" => "4x6x1"}
      expect {
        s.validate_parameters(params)
      }.to raise_error(/shape must be smaller than/)
    end
  end

  describe "#submit_job" do

    before(:each) do
      FileUtils.mkdir_p("work_test")
      FileUtils.mkdir_p("log_test")
    end

    after(:each) do
      FileUtils.rm_rf("work_test")
      FileUtils.rm_rf("log_test")
    end

    it "submits job by pjsub" do
      s = Xsub::K.new
      command = "cd #{Dir.pwd}/work_test && pjsub #{Dir.pwd}/job.sh -o #{Dir.pwd}/log_test/%j.o.txt -e #{Dir.pwd}/log_test/%j.e.txt --spath #{Dir.pwd}/log_test/%j.i.txt < /dev/null"
      out = "[INFO] PJM 0000 pjsub Job 112109 submitted."
      expect(s).to receive(:`).with(command).and_return(out)
      out = s.submit_job("job.sh", "work_test", "log_test")
      expect( out[:job_id] ).to eq "112109"
    end

    it "prints log in the log directory" do
      s = Xsub::K.new
      out = "[INFO] PJM 0000 pjsub Job 112109 submitted."
      allow(s).to receive(:`).and_return(out)
      s.submit_job("job.sh", "work_test", "log_test")
      expect( File.exist?("log_test/xsub.log") ).to be_truthy
    end

    it "raises an error when staging option is invalid" do
      s = Xsub::K.new
      out = <<EOS
[ERR.] PJM 0007 pjsub Staging option error (3)
Refer to the staging information file. (J5333b14881e31ebcd2000001.sh.s2366652)
EOS
      allow(s).to receive(:`).and_return(out)
      expect {
        s.submit_job("job.sh", "work_test", "log_test")
      }.to raise_error(/staging option error/)
    end
  end

  describe "#status" do

    it "returns :queued status by qstat" do
      s = Xsub::K.new
      command = "pjstat 112111"
      stat = <<EOS
        ACCEPT QUEUED  STGIN  READY RUNING RUNOUT STGOUT   HOLD  ERROR   TOTAL
       0      0      0      0      1      0      0      0      0       1
s      0      0      0      0      1      0      0      0      0       1

JOB_ID     JOB_NAME   MD ST  USER     START_DATE      ELAPSE_LIM NODE_REQUIRE
112111     test.sh    NM QUE test     10/29 18:42:44  0024:00:00 1
EOS
      expect(s).to receive(:`).with(command).and_return(stat)
      out = s.status("112111")
      expect( out[:status] ).to eq :queued
    end

    it "returns :running status by qstat" do
      s = Xsub::K.new
      command = "pjstat 112111"
      stat = <<EOS
  ACCEPT QUEUED  STGIN  READY RUNING RUNOUT STGOUT   HOLD  ERROR   TOTAL
       0      0      0      0      1      0      0      0      0       1
s      0      0      0      0      1      0      0      0      0       1

JOB_ID     JOB_NAME   MD ST  USER     START_DATE      ELAPSE_LIM NODE_REQUIRE
112111     test.sh    NM RUN test     10/29 18:42:44  0024:00:00 1
EOS
      expect(s).to receive(:`).with(command).and_return(stat)
      out = s.status("112111")
      expect( out[:status] ).to eq :running
    end

    it "returns :finished status by pjstat" do
      s = Xsub::K.new
      command = "pjstat 112111"
      stat = <<EOS
  ACCEPT QUEUED  STGIN  READY RUNING RUNOUT STGOUT   HOLD  ERROR   TOTAL
       0      0      0      0      1      0      0      0      0       1
s      0      0      0      0      1      0      0      0      0       1

JOB_ID     JOB_NAME   MD ST  USER     START_DATE      ELAPSE_LIM NODE_REQUIRE
112111     test.sh    NM EXT test     10/29 18:42:44  0024:00:00 1
EOS
      expect(s).to receive(:`).with(command).and_return(stat)
      out = s.status("112111")
      expect( out[:status] ).to eq :finished
    end

    it "returns :finished status by qstat when job_id is not found" do
      s = Xsub::K.new
      command = "pjstat 112111"
      stat = <<EOS
  ACCEPT QUEUED  STGIN  READY RUNING RUNOUT STGOUT   HOLD  ERROR   TOTAL
       0      0      0      0      0      0      0      0      0       0
s      0      0      0      0      0      0      0      0      0       0
EOS
      expect(s).to receive(:`).with(command).and_return(stat)
      out = s.status("112111")
      expect( out[:status] ).to eq :finished
    end
  end

  describe "#all_status" do

    it "returns status in string" do
      s = Xsub::K.new
      expect(s).to receive(:`).with("pjstat").and_return("abc")
      expect( s.all_status ).to eq "abc"
    end
  end

  describe "#delete" do

    it "cancels job by qdel command" do
      s = Xsub::K.new
      expect(s).to receive(:`).with("pjdel 112113")
      s.delete("112113")
    end
  end
end

