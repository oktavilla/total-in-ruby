require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "AccountStart" do
      let :line do
        double "Line", attributes: {}
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
        allow(Document::Account).to receive :new

        AccountStart.call line, contexts

        expect(Document::Account).to have_received(:new).with line.attributes
      end

      it "adds the account to the document" do
        fake_account = double "Document::Account"
        allow(Document::Account).to receive(:new) { fake_account }

        AccountStart.call line, contexts

        expect(document.accounts).to include fake_account
      end

      it "sets the account as the current context" do
        fake_account = double "Document::Account"
        allow(Document::Account).to receive(:new) { fake_account }

        new_contexts = AccountStart.call line, contexts

        expect(new_contexts.current).to be fake_account
      end
    end
  end
end
