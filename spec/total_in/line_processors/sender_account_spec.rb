require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "SenderAccount" do
      let :line do
        double "Line", attributes: {}
      end

      describe "when the current context is a Document::SenderAccount" do
        it "adds the line values to the sender as name" do
          sender_account = Document::SenderAccount.new
          contexts = Contexts.new sender_account
          allow(sender_account).to receive(:assign_attributes)

          SenderAccount.call line, contexts

          expect(sender_account).to have_received(:assign_attributes).with line.attributes
        end
      end

      describe "when the current context is something else" do
        let! :sender_account do
          Document::SenderAccount.new
        end

        before do
          allow(Document::SenderAccount).to receive(:new) { sender_account }
        end

        it "adds a new Document::SenderAccount to the nearest transaction and appends it to the contexts" do
          transaction = Document::Transaction.new
          contexts = Contexts.new transaction
          allow(sender_account).to receive(:assign_attributes)

          new_contexts = SenderAccount.call line, contexts

          expect(transaction.sender_account).to eq sender_account
          expect(new_contexts.current).to be sender_account
          expect(sender_account).to have_received(:assign_attributes).with line.attributes
        end
      end
    end
  end
end
