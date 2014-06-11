describe XScheduler do

  describe ".show_param" do

    it "prints parameters in json" do
      json = XScheduler.params_in_json
      JSON.load(json).should eq XScheduler.param
    end
  end
end
