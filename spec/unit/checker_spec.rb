require 'stringio'

RSpec.describe Xsub::Checker do

  class Dummy < Xsub::Scheduler

    def status(job_id)
      return {"status" => "running"}
    end

    def all_status
      return {"raw_output" => "foo"}
    end
  end

  before(:each) do
    @checker = Xsub::Checker.new( Dummy.new )
    $stdout = StringIO.new  # supress stdout
  end

  after(:each) do
    $stdout = STDOUT
  end

  context "when job_id is given" do

    it "calls Scheduler#status" do
      argv = %w(1234)
      expect(@checker.scheduler).to receive(:status).with("1234").and_call_original
      @checker.run(argv)
    end
  end

  context "when job_id is not given" do

    it "return status of all the running jobs" do
      expect(@checker.scheduler).to receive(:all_status).and_call_original
      @checker.run([])
    end
  end
end

