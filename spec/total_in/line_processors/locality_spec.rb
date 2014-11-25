require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe Locality do
      let :line do
        double "Line", attributes: {}
      end

      describe "when the current context is a Document::Sender" do
        it "adds the line values to the sender as name" do
          sender = Document::Sender.new
          contexts = Contexts.new sender
          allow(sender).to receive(:assign_attributes)

          Locality.new(Document::Sender).call line, contexts

          expect(sender).to have_received(:assign_attributes).with line.attributes
        end
      end

      describe "when the current context is something else" do
        let! :sender do
          Document::Sender.new
        end

        before do
          allow(Document::Sender).to receive(:new) { sender }
        end

        it "adds a new Document::Sender to the nearest transaction and appends it to the contexts" do
          transaction = Document::Transaction.new
          contexts = Contexts.new transaction
          allow(sender).to receive(:assign_attributes)

          new_contexts = Locality.new(Document::Sender).call line, contexts

          expect(transaction.sender).to eq sender
          expect(new_contexts.current).to be sender
          expect(sender).to have_received(:assign_attributes).with line.attributes
        end
      end
    end
  end
end
