require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "International" do
      let :line do
        double "LineParsers::International", attributes: { cost: 20, amount: 300 }
      end

      let :contexts do
        Contexts.new Document::Transaction.new
      end

      it "moves to the nearest transaction" do
        contexts.add Document::Sender.new

        c = International.call line, contexts

        expect(c.current).to be_a Document::Transaction
      end

      it "assigns the transaction a new International with the line's attributes" do
        c = International.call line, contexts
        international = c.current.international

        expect(international).to be_a Document::International
        expect(international.attributes).to eq line.attributes
      end
    end
  end
end
