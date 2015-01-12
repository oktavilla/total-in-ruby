require "total_in/line_parsers"

module TotalIn
  module LineParsers
    RSpec.describe DocumentStart do
      let :document_start do
        DocumentStart.new "00TI222222    2011102504133012345601TL1TOTALIN"
      end

      it "extracts the id" do
        expect(document_start.id).to eq "TI222222"
      end

      it "extracts the created at timestamp" do
        expect(document_start.created_at).to be_a Time
        expect(document_start.created_at.strftime("%Y-%m-%d %H:%M:%S")).to eq "2011-10-25 04:13:30"
      end

      it "parses the deliver number" do
        expect(document_start.delivery_number).to eq 1
      end

      it "parses the file type" do
        expect(document_start.file_type).to eq "TL1"
      end

      it "parses file name" do
        expect(document_start.name).to eq "TOTALIN"
      end
    end
  end
end
