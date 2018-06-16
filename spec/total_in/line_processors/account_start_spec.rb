require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "AccountStart" do
      let :line do
        double "LineParsers::AccountStart", attributes: {
          account_number: "12345",
          currency: "SEK",
          date: Date.new
        }
      end

      let :document do
        Document.new
      end

      let :contexts do
        Contexts.new
      end

      before do
        contexts.add document
      end

      it "instantiates a new account with the line attributes" do
        c = AccountStart.call line, contexts
        account = c.current

        expect(account).to be_a Document::Account
        expect(account.attributes).to eq line.attributes
      end

      it "adds the account to the document" do
        expect(document.accounts).to be_empty

        c = AccountStart.call line, contexts

        expect(document.accounts.size).to eq 1
        expect(document.accounts.first).to eq c.current
      end
    end
  end
end
