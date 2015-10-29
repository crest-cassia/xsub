RSpec.describe Xsub::Scheduler do

  class Dummy < Xsub::Scheduler
  end
  class Dummy2 < Xsub::Scheduler
  end

  describe ".get_scheduler" do

    it "returns the specified scheduler" do
      scheduler = Xsub::Scheduler.get_scheduler("dummy2")
      expect( scheduler ).to eq Dummy2
    end

    it "raises an error when matching scheduler is not found" do
      expect {
        Xsub::Scheduler.get_scheduler("dummy3")
      }.to raise_error /scheduler is not found/
    end
  end
end

