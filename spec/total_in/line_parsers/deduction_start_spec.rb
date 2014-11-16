require "total_in/line_parsers"

module TotalIn
  module LineParsers
    RSpec.describe DeductionStart do
      let :deduction_start do
        DeductionStart.new "25987654123                          000000000052550222223333344444572          "
      end

      describe "#reference_number" do
        it "is nil if unfound (only zeros) or blank" do
          deduction_start = DeductionStart.new "200000000000000000000000000          0000000002109002222233333444446734523455   "
          expect(deduction_start.reference_number).to be nil

          deduction_start = DeductionStart.new "20                                   0000000002109002222233333444446734523455   "
          expect(deduction_start.reference_number).to be nil
        end

        it "is parsed if non blank" do
          expect(deduction_start.reference_number).to eq "987654123"
        end
      end

      it "parses the amount" do
        expect(deduction_start.amount).to eq 52550
      end

      it "parses the serial number" do
        expect(deduction_start.serial_number).to eq 22222333334444457
      end

      it "parses the code" do
        expect(deduction_start.code).to eq 2
      end

      describe "receiving bankgiro number" do
        it "is nil if missing" do
          expect(deduction_start.receiving_bankgiro_number).to be nil
        end

        it "is parsed if non blank" do
          deduction_start = DeductionStart.new "25987654123                          00000000005255022222333334444457   654321  "
          expect(deduction_start.receiving_bankgiro_number).to eq "654321"
        end
      end
    end
  end
end


