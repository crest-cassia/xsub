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
      :out => <<~EOS,
          PID TTY           TIME CMD
        53839 ttys000    0:00.08 /usr/home/job.sh
        EOS
      :rc => 0,
      :status => :running
    },
    {
      :job_id => "53839",
      :command => "ps -p 53839",
      :out => <<~EOS,
          PID TTY           TIME CMD
        EOS
      :rc => 1,
      :status => :finished
    }
  ]

  it_behaves_like "Scheduler#status", status_test_cases

  multiple_status_test_cases = [
    {
      :job_ids => ["53839", "53840"],
      :commands => {
        "ps -p 53839" => [0, <<~EOS],
              PID TTY           TIME CMD
            53839 ttys000    0:00.08 /usr/home/job.sh
          EOS
        "ps -p 53840" => [1, <<~EOS]
          PID TTY           TIME CMD
          EOS
      },
      :expected => {
        "53839" => {:status => :running},
        "53840" => {:status => :finished}
      }
    }
  ]

  it_behaves_like "Scheduler#multiple_status", multiple_status_test_cases

  it_behaves_like "Scheduler#all_status", "ps uxr | head -n 10"

  describe "#delete" do

    it "cancels job by kill command" do
      s = described_class.new
      `exit 0 > /dev/null`  # setting $? to 0
      expect(s).to receive(:system).with("kill -0 1234") { `exit 0 > /dev/null` }
      expect(s).to receive(:`).with("ps --ppid 1234 -o \"pid=\"").and_return("5678")
      expect(s).to receive(:system).with("kill -0 5678") { `exit 0 > /dev/null` }
      expect(s).to receive(:`).with("ps --ppid 5678 -o \"pid=\"").and_return("9012")
      expect(s).to receive(:system).with("kill -0 9012") { `exit 0 > /dev/null` }
      expect(s).to receive(:`).with("ps --ppid 9012 -o \"pid=\"").and_return("")
      expect(s).to receive(:system).with("kill -KILL 9012 5678 1234")
      s.delete("1234")
    end

=begin
    it "raises an error when kill command fails" do
      s = described_class.new
      `exit 0 > /dev/null`  # setting $? to 0
      expect(s).to receive(:`).with("ps -p 1234 -o \"pgid\"").and_return("5678")
      expect(s).to receive(:system).with("kill -TERM -5678") { `exit 1 > /dev/null` }
      expect {
        s.delete("1234")
      }.to raise_error(/kill command failed/)
    end
=end
    
    it "raises an error when process is not found" do
      s = described_class.new
      `exit 0 > /dev/null`  # setting $? to 0
      expect(s).to receive(:system).with("kill -0 1234") { `exit 1 > /dev/null` }
      expect {
        s.delete("1234")
      }.to raise_error(/Process is not found/)
    end
  end
end

