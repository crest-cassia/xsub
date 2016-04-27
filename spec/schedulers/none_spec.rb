require File.join( File.dirname(__FILE__), '../support/shared_examples_for_scheduler')

RSpec.describe Xsub::None do

  it_behaves_like "Scheduler::CONSTANTS"


  valid_params = [
    {"mpi_procs" => 4, "omp_threads" => 8}
  ]
  invalid_params = [
  ]

  it_behaves_like "Scheduler#validate_parameters", valid_params, invalid_params

  submit_test_ok_cases = [
    {
      :command => "nohup bash #{Dir.pwd}/job.sh > /dev/null 2>&1 < /dev/null & echo $!",
      :out => "53839",
      :rc => 0,
      :job_id => "53839"
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
      :job_id => "53839",
      :command => "ps -p 53839",
      :out => <<EOS,
  PID TTY           TIME CMD
53839 ttys000    0:00.08 /usr/home/job.sh
EOS
      :rc => 0,
      :status => :running
    },
    {
      :job_id => "53839",
      :command => "ps -p 53839",
      :out => <<EOS,
  PID TTY           TIME CMD
EOS
      :rc => 1,
      :status => :finished
    }
  ]

  it_behaves_like "Scheduler#status", status_test_cases

  it_behaves_like "Scheduler#all_status", "ps uxr | head -n 10"

  describe "#delete" do

    it "cancels job by kill command" do
      s = described_class.new
      `exit 0 > /dev/null`  # setting $? to 0
      expect(s).to receive(:`).with("ps -p 1234 -o \"pgid\"").and_return("5678")
      expect(s).to receive(:system).with("kill -TERM -5678")
      s.delete("1234")
    end

    it "raises an error when kill command fails" do
      s = described_class.new
      `exit 0 > /dev/null`  # setting $? to 0
      expect(s).to receive(:`).with("ps -p 1234 -o \"pgid\"").and_return("5678")
      expect(s).to receive(:system).with("kill -TERM -5678") { `exit 1 > /dev/null` }
      expect {
        s.delete("1234")
      }.to raise_error(/kill command failed/)
    end
    
    it "raises an error when process is not found" do
      s = described_class.new
      `exit 0 > /dev/null`  # setting $? to 0
      expect(s).to receive(:`).with("ps -p 1234 -o \"pgid\"") { `exit 1 > /dev/null` }
      expect {
        s.delete("1234")
      }.to raise_error(/Process is not found/)
    end
  end
end

