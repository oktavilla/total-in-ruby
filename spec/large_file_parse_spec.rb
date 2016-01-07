require "total_in"

RSpec.describe TotalIn do
  describe ".parse" do
    it "does not throw a stack overflow error on parsing large files" do
      content = File.read File.join(__dir__, "fixtures/total_in_large.txt"), encoding: "iso-8859-1"

      expect { TotalIn.parse content }.to_not raise_error
    end
  end
end

