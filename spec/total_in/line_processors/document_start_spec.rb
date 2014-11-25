require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "DocumentStart" do
      let :line do
        double "Line", attributes: {}
      end

      it "instantiates a new document with the line attributes" do
        allow(Document).to receive :new

        DocumentStart.call line, Contexts.new

        expect(Document).to have_received(:new).with line.attributes
      end

      it "sets the document as the current context" do
        fake_document = double "Document"
        allow(Document).to receive(:new) { fake_document }

        contexts = DocumentStart.call line, Contexts.new

        expect(contexts.current).to be fake_document
      end
    end
  end
end
