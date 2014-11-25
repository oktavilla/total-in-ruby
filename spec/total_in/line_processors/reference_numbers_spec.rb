require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "ReferenceNumbers" do
      let :line do
        double "Line", values: ["one", "two"]
      end

      let :current_context do
        double "SomeContext", reference_numbers: ["original"]
      end

      it "adds the line values to the current context's reference_numbers" do
        contexts = Contexts.new current_context

        ReferenceNumbers.call line, contexts

        expect(contexts.current.reference_numbers).to eq ["original", "one", "two"]
      end
    end
  end
end
