require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe AccountEnd do
      let :line do
        double "LineParsers::AccountEnd", attributes: {
          number_of_transactions: 1,
          amount: 20,
          statement_reference: "123"
        }
      end

      let :account do
        Document::Account.new account_number: "213"
      end

      let :contexts do
        Contexts.new [Document.new, account, Document::Payment.new]
      end

      it "moves to the nearest account and assigns the line attributes" do
        AccountEnd.call line, contexts

        expect(account.attributes).to eq({
          account_number: "213",
          number_of_transactions: 1,
          amount: 20,
          statement_reference: "123"
        })
      end

      it "sets the account as the current context" do
        c = AccountEnd.call line, contexts

        expect(c.current).to be account
      end
    end
  end
end

