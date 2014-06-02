describe AnyScheduler do

  describe ".show_param" do

    it "prints parameters in json" do
      json = AnyScheduler.params_in_json
      JSON.load(json).should eq AnyScheduler.param
    end
  end
end
