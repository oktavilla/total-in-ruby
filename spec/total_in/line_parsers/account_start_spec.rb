require "total_in/line_parsers"

module TotalIn
  module LineParsers
    RSpec.describe AccountStart do
      let :account_start do
        AccountStart.new "1010181                               SEK20111024"
      end

      it "parses the account number" do
        expect(account_start.account_number).to eq "10181"
      end

      it "parses the currency" do
        expect(account_start.currency).to eq "SEK"
      end

      it "parses the posting date" do
        expect(account_start.date).to be_a Date
        expect(account_start.date.to_s).to eq "2011-10-24"
      end
    end
  end
end
