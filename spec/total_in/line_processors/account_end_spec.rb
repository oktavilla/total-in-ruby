require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "AccountEnd" do
      let :line do
        double "Line", attributes: {}
      end

      let :account do
        Document::Account.new
      end

      let :contexts do
        Contexts.new [Document.new, account, Document::Payment.new]
      end

      it "moves to the nearest account and assigns the line attributes" do
        allow(account).to receive :assign_attributes

        AccountEnd.call line, contexts

        expect(account).to have_received(:assign_attributes).with line.attributes
      end

      it "sets the account as the current context" do
        new_contexts = AccountEnd.call line, contexts

        expect(new_contexts.current).to be account
      end
    end
  end
end

