require "total_in/contexts"
require "total_in/line_processors"

module TotalIn
  module LineProcessors
    RSpec.describe "PaymentStart" do
      let :line do
        double "Line", attributes: {}, reference_number: "1234567890"
      end

      let :account do
        Document::Account.new
      end

      let! :contexts do
        Contexts.new [Document.new, account, Document::Payment.new]
      end

      it "adds a new payment to the nearest account" do
        payment = Document::Payment.new
        allow(Document::Payment).to receive(:new) { payment }

        PaymentStart.call line, contexts

        expect(account.payments).to include payment
      end

      it "sets the payment as the current context" do
        payment = Document::Payment.new
        allow(Document::Payment).to receive(:new) { payment }

        new_contexts = PaymentStart.call line, contexts

        expect(new_contexts.current).to be payment
      end

      it "assigns the line attributes to the account" do
        payment = Document::Payment.new
        allow(Document::Payment).to receive(:new) { payment }

        PaymentStart.call line, contexts

        expect(Document::Payment).to have_received(:new).with(line.attributes)
      end

      it "adds the line reference number to the payment" do
        new_contexts = PaymentStart.call line, contexts

        expect(new_contexts.current.reference_numbers).to include "1234567890"
      end
    end
  end
end
