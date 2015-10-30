require 'stringio'

RSpec.shared_examples "Scheduler::CONSTANTS" do

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
end

RSpec.shared_examples "Scheduler#validate_parameters" do |valid_prms, invalid_prms|

  describe "#validate_parameters" do

    describe "valid cases" do
      valid_prms.each_with_index do |valid_param,idx|

        it "does not raise an error when valid parameters are given (#{idx+1})" do
          s = described_class.new
          expect {
            s.validate_parameters( valid_param )
          }.to_not raise_error
        end
      end
    end

    describe "invalid cases" do
      invalid_prms.each_with_index do |(invalid_param,msg),idx|

        it "raises an error with invalid parameters (#{idx+1})" do
          s = described_class.new
          expect {
            s.validate_parameters( invalid_param )
          }.to raise_error(msg)
        end
      end
    end
  end
end

RSpec.shared_examples "Scheduler#submit_job" do |ok_cases,ng_cases|

  describe "#submit_job" do

    before(:each) do
      FileUtils.mkdir_p("work_test")
      FileUtils.mkdir_p("log_test")
    end

    after(:each) do
      FileUtils.rm_rf("work_test")
      FileUtils.rm_rf("log_test")
    end

    ok_cases.each_with_index do |ok_case,idx|

      it "submits job correctly (#{idx+1})" do
        s = described_class.new
        cmd = ok_case[:command]
        out = ok_case[:out]
        rc = ok_case[:rc]
        job_id = ok_case[:job_id]
        expect(s).to receive(:`) {|arg|
          expect(arg).to eq cmd if cmd
          `exit #{rc} > /dev/null` if rc
          out
        }
        ret = s.submit_job("job.sh", "work_test", "log_test", StringIO.new)
        expect( ret[:job_id] ).to eq job_id
      end
    end

    ng_cases.each_with_index do |ng_case,idx|

      it "raises an error when submission fails (#{idx+1})" do
        s = described_class.new
        cmd = ng_case[:command]
        out = ng_case[:out]
        rc = ng_case[:rc]
        error = ng_case[:error]
        expect(s).to receive(:`) {|arg|
          expect(arg).to eq cmd if cmd
          `exit #{rc} > /dev/null` if rc
          out
        }
        expect {
          s.submit_job("job.sh", "work_test", "log_test", StringIO.new)
        }.to raise_error(error)
      end
    end
  end
end

RSpec.shared_examples "Scheduler#status" do |cases|

  describe "#status" do

    cases.each_with_index do |test_case,idx|

      it "returns status (#{idx+1})" do
        cmd = test_case[:command]
        rc = test_case[:rc]
        job_id = test_case[:job_id]

        s = described_class.new
        expect(s).to receive(:`) {|arg|
          expect(arg).to eq cmd if cmd
          `exit #{rc} > /dev/null` if rc
          test_case[:out]
        }
        ret = s.status( test_case[:job_id] )
        expect( ret[:status] ).to eq test_case[:status]
      end
    end
  end
end

RSpec.shared_examples "Scheduler#all_status" do |expected_cmd|

  describe "#all_status" do
    
    it "return status in string" do
      s = described_class.new
      expect(s).to receive(:`).with(expected_cmd).and_return("abc")
      expect( s.all_status ).to eq "abc"
    end
  end
end

RSpec.shared_examples "Scheduler#delete" do |expected_cmd|

  describe "#delete" do

    it "cancels job by #{expected_cmd}" do
      s = described_class.new
      expect(s).to receive(:`).with("#{expected_cmd} 1234") do
        `exit 0 > /dev/null`
        ""
      end
      s.delete("1234")
    end
  end
end

