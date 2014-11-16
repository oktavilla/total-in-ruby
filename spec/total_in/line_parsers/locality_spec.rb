require "total_in/line_parsers"

module TotalIn
  module LineParsers
    RSpec.describe Locality do
      let :locality do
        Locality.new "5211111    TESTVIKEN                          SE                               "
      end

      it "parses the postal code" do
        expect(locality.postal_code).to eq "11111"
      end

      it "parses the city" do
        expect(locality.city).to eq "TESTVIKEN"
      end

      it "parses the country code" do
        expect(locality.country_code).to eq "SE"
      end
    end
  end
end
