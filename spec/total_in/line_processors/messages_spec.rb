require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "Names" do
      let :line do
        double "Line", values: ["one", "two"]
      end

      let :current_context do
        double "SomeContext", add_message: nil
      end

      it "adds the line values to the current context's reference_numbers" do
        contexts = Contexts.new current_context

        Messages.call line, contexts

        expect(current_context).to have_received(:add_message).with "one"
        expect(current_context).to have_received(:add_message).with "two"
      end
    end
  end
end
