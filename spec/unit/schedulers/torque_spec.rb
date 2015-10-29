require 'stringio'

RSpec.describe Xsub::Torque do

  before(:each) do
    `exit 0`  # set default exit code
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
      s = Xsub::Torque.new
      params = {"mpi_procs" => 4, "omp_threads" => 8, "ppn" => 8}
      expect {
        s.validate_parameters(params)
      }.to_not raise_error
    end

    it "raises an error when (mpi_procs*omp_threads) is not a multiple of ppn" do
      s = Xsub::Torque.new
      params = {"mpi_procs" => 4, "omp_threads" => 8, "ppn" => 6}
      expect {
        s.validate_parameters(params)
      }.to raise_error(/must be a multiple of ppn/)
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

    it "submits job by qsub" do
      s = Xsub::Torque.new
      command = "qsub #{Dir.pwd}/job.sh -d #{Dir.pwd}/work_test -o #{Dir.pwd}/log_test -e #{Dir.pwd}/log_test"
      expect(s).to receive(:`).with(command).and_return("19352.localhost")
      out = s.submit_job("job.sh", "work_test", "log_test")
      expect( out[:job_id] ).to eq 19352
    end

    it "prints log in the log directory" do
      s = Xsub::Torque.new
      allow(s).to receive(:`).and_return("19352.localhost")
      s.submit_job("job.sh", "work_test", "log_test")
      expect( File.exist?("log_test/xsub.log") ).to be_truthy
    end
  end

  describe "#status" do

    it "returns :queued status by qstat" do
      s = Xsub::Torque.new
      command = "qstat 19352"
      stat = <<EOS
Job id                    Name             User            Time Use S Queue
------------------------- ---------------- --------------- -------- - -----
19352.localhost           job.sh           test_user              0 Q batch
EOS
      expect(s).to receive(:`).with(command).and_return(stat)
      out = s.status(19352)
      expect( out[:status] ).to eq :queued
    end

    it "returns :running status by qstat" do
      s = Xsub::Torque.new
      command = "qstat 19352"
      stat = <<EOS
Job id                    Name             User            Time Use S Queue
------------------------- ---------------- --------------- -------- - -----
19352.localhost           job.sh           test_user              0 R batch
EOS
      expect(s).to receive(:`).with(command).and_return(stat)
      out = s.status(19352)
      expect( out[:status] ).to eq :running
    end

    it "returns :finished status by qstat" do
      s = Xsub::Torque.new
      command = "qstat 19352"
      stat = <<EOS
Job id                    Name             User            Time Use S Queue
------------------------- ---------------- --------------- -------- - -----
19352.localhost           job.sh           test_user              0 C batch
EOS
      expect(s).to receive(:`).with(command).and_return(stat)
      out = s.status(19352)
      expect( out[:status] ).to eq :finished
    end

    it "returns :finished status by qstat when job_id is not found" do
      s = Xsub::Torque.new
      command = "qstat 19352"
      expect(s).to receive(:`).with(command) { `exit 153` }
      out = s.status(19352)
      expect( out[:status] ).to eq :finished
    end
  end

  describe "#all_status" do

    it "returns status in string" do
      s = Xsub::Torque.new
      expect(s).to receive(:`).with("qstat && pbsnodes -a").and_return("abc")
      expect( s.all_status ).to eq "abc"
    end
  end

  describe "#delete" do

    it "cancels job by qdel command" do
      s = Xsub::Torque.new
      expect(s).to receive(:`).with("qdel 12345")
      s.delete("12345")
    end
  end
end

