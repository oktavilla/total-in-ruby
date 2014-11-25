require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "DeductionStart" do
      let :line do
        double "Line", attributes: {}, reference_number: "1234567890"
      end

      let :account do
        Document::Account.new
      end

      let! :contexts do
        Contexts.new [Document.new, account, Document::Deduction.new]
      end

      it "adds a new deduction to the nearest account" do
        deduction = Document::Deduction.new
        allow(Document::Deduction).to receive(:new) { deduction }

        DeductionStart.call line, contexts

        expect(account.deductions).to include deduction
      end

      it "sets the deduction as the current context" do
        deduction = Document::Deduction.new
        allow(Document::Deduction).to receive(:new) { deduction }

        new_contexts = DeductionStart.call line, contexts

        expect(new_contexts.current).to be deduction
      end

      it "assigns the line attributes to the account" do
        deduction = Document::Deduction.new
        allow(Document::Deduction).to receive(:new) { deduction }

        DeductionStart.call line, contexts

        expect(Document::Deduction).to have_received(:new).with(line.attributes)
      end

      it "adds the line reference number to the deduction" do
        new_contexts = DeductionStart.call line, contexts

        expect(new_contexts.current.reference_numbers).to include "1234567890"
      end
    end
  end
end

