RSpec.describe Xsub::Template do

  describe ".render" do

    it "renders template" do
      template = <<-EOS
        foo: <%= foo %>
        bar: <%= bar %>
      EOS

      rendered = Xsub::Template.render(template, {:foo => 1, :bar => 2} )

      expected = <<-EOS
        foo: 1
        bar: 2
      EOS
      expect( rendered ).to eq expected
    end
  end
end


