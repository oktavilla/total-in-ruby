require "support/shared_examples_for_values_line_parsers"
require "total_in/line_parsers"

module TotalIn
  module LineParsers
    RSpec.describe ReferenceNumbers do
      it_behaves_like "a values line parser"
    end
  end
end

