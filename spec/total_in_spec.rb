require "total_in"

RSpec.describe TotalIn do
  describe "#parse" do
    it "returns the parser results" do
      text = "some total-in text"
      parser = double "Parser", result: "result"
      expect(TotalIn::Parser).to receive(:new).with(text) { parser }

      expect(TotalIn.parse(text)).to eq "result"
    end
  end
end
