require "total_in/line_parsers"

module TotalIn
  module LineParsers
    RSpec.describe International do
      let :international do
        International.new "7010000000000000 EUR                  000000000105000EUR000000088000            "
      end

      it "parses the cost" do
        expect(international.cost).to eq 10000000000000
      end

      it "parses the cost currency" do
        expect(international.cost_currency).to eq "EUR"
      end

      it "parses the amount" do
        expect(international.amount).to eq 105000
      end

      it "parses the amount currency" do
        expect(international.amount_currency).to eq "EUR"
      end

      it "parses the exchange rate" do
        expect(international.exchange_rate).to eq 88000
      end
    end
  end
end

