require "total_in/line_parsers"

module TotalIn
  module LineParsers
    RSpec.describe AccountEnd do
      let :account_end do
        AccountEnd.new "90000000260000000000191900020111024001"
      end

      it "parses the number of tranactions" do
        expect(account_end.number_of_transactions).to eq 26
      end

      it "parses the amount" do
        expect(account_end.amount).to eq 1919000
      end

      it "parses the statement reference" do
        expect(account_end.statement_reference).to eq "20111024001"
      end
    end
  end
end
