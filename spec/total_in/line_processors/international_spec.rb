require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "International" do
      let :line do
        double "Line", attributes: {}
      end

      let :transaction do
        Document::Transaction.new
      end

      let :contexts do
        Contexts.new transaction
      end

      it "instantiates a new International with the line attributes" do
        international = double "Document::International"
        allow(Document::International).to receive(:new) { international }

        International.call line, contexts

        expect(Document::International).to have_received(:new).with line.attributes
      end

      it "assigns the international instance to the transaction" do
        international = double "Document::International"
        allow(Document::International).to receive(:new) { international }

        International.call line, contexts

        expect(transaction.international).to be international
      end

      it "moves to the nearest transaction" do
        contexts.add Document::Sender.new

        new_contexts = International.call line, contexts

        expect(new_contexts.current).to be transaction
      end
    end
  end
end
