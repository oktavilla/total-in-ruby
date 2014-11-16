RSpec.shared_examples "a values line parser" do
  describe "#values" do
    it "finds first value" do
      line = described_class.new "  847c7f90402aa750a7e257ed149f10834cy                                           "

      expect(line.values).to eq ["847c7f90402aa750a7e257ed149f10834cy"]
    end

    it "finds both values" do
      line = described_class.new "  847c7f90402aa750a7e257ed149f10834cyf410cae4e8d1a5574y20c78702907a47f39        "

      expect(line.values).to eq ["847c7f90402aa750a7e257ed149f10834cy", "f410cae4e8d1a5574y20c78702907a47f39"]
    end
  end
end
