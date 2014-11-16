require "total_in/line_parsers"

module TotalIn
  module LineParsers
    RSpec.describe DocumentEnd do
      let :document_end do
        DocumentEnd.new "99000000000000061"
      end

      it "parses the number of lines" do
        expect(document_end.number_of_lines).to eq 61
      end
    end
  end
end
