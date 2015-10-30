require 'stringio'

RSpec.describe Xsub::Checker do

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
      out = JSON.load($stdout.flush.string)
      expect(out).to be_a(Hash)
      expect(out.has_key?("status")).to be_truthy
    end
  end

  context "when job_id is not given" do

    it "return status of all the running jobs" do
      expect(@checker.scheduler).to receive(:all_status).and_call_original
      @checker.run([])
      expect( $stdout.string ).to_not be_empty
    end
  end
end

