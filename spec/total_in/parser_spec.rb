require "total_in/parser"

module TotalIn
  RSpec.describe Parser do
    describe "ensuring the file is valid" do
      it "accepts a valid file" do
        valid_file = "00TI222222    2011102504133012345601TL1TOTALIN                                  "
        expect{ Parser.new(valid_file) }.to_not raise_error
      end

      it "should start with 00" do
        invalid_file = "99TI222222    2011102504133012345601TL1TOTALIN                                  "
        expect{ Parser.new(invalid_file) }.to raise_error{ TotalIn::InvalidFileFormatError }
      end

      it "expects the TL1 file type indicator" do
        invalid_file = "00TI222222    2011102504133012345601TL2TOTALIN                                  "
        expect{ Parser.new(invalid_file) }.to raise_error{ TotalIn::InvalidFileFormatError }
      end
    end
  end
end
