require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "DocumentEnd" do
      class Thing
      end

      let :line do
        double "Line", number_of_lines: 35
      end

      it "moves to the nearest document context" do
        document = Document.new
        contexts = Contexts.new [Thing.new, document, Thing.new, Thing.new]

        DocumentEnd.call line, contexts

        expect(contexts.current).to eq document
      end

      it "sets the number of lines on the document" do
        document = Document.new

        DocumentEnd.call line, Contexts.new(document)

        expect(document.number_of_lines).to eq 35
      end
    end
  end
end
