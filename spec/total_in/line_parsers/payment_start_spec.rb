require "total_in/line_parsers"

module TotalIn
  module LineParsers
    RSpec.describe PaymentStart do
      let :payment_start do
        PaymentStart.new "2038952678900                        00000000001050022222333334444477           "
      end

      describe "#reference_number" do
        it "is nil if unfound (only zeros) or blank" do
          payment_start = PaymentStart.new "200000000000000000000000000          0000000002109002222233333444446734523455   "
          expect(payment_start.reference_number).to be nil

          payment_start = PaymentStart.new "20                                   0000000002109002222233333444446734523455   "
          expect(payment_start.reference_number).to be nil
        end

        it "is parsed if non blank" do
          expect(payment_start.reference_number).to eq "38952678900"
        end
      end

      it "parses the amount" do
        expect(payment_start.amount).to eq 10500
      end

      it "parses the serial number" do
        expect(payment_start.serial_number).to eq 22222333334444477
      end

      describe "receiving bankgiro number" do
        it "is nil if missing" do
          expect(payment_start.receiving_bankgiro_number).to be nil
        end

        it "is parsed if non blank" do
          payment_start = PaymentStart.new "2038952678900                        0000000000105002222233333444447712345678   "
          expect(payment_start.receiving_bankgiro_number).to eq "12345678"
        end
      end
    end
  end
end

