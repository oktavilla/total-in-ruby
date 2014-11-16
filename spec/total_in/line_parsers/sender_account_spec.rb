require "total_in/line_parsers"

module TotalIn
  module LineParsers
    RSpec.describe SenderAccount do
      let :sender_account do
        SenderAccount.new "6098765433                            29999999999                               "
      end

      it "parses the account number" do
        expect(sender_account.account_number).to eq "98765433"
      end

      it "parses the city" do
        expect(sender_account.origin_code).to eq 2
      end

      it "parses the organization number code" do
        expect(sender_account.company_organization_number).to eq "9999999999"
      end
    end
  end
end
