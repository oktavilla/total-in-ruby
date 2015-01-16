require "total_in/document"

module TotalIn
  RSpec.describe Document do
    describe "#transaction_date" do
      it "delegates to the first account date it finds" do
        document = Document.new
        document.accounts << Document::Account.new
        document.accounts << Document::Account.new(date: "some date")

        expect(document.transaction_date).to eq "some date"
      end

      it "returns nil if there are no account dates" do
        expect(Document.new.transaction_date).to be nil
      end
    end

    describe "#payments" do
      it "returns payments from all accounts" do
        document = Document.new
        account_one = Document::Account.new
        payment_one = Document::Payment.new
        account_one.payments << payment_one

        account_two = Document::Account.new
        payment_two = Document::Payment.new
        account_two.payments << payment_two

        document.accounts << account_one
        document.accounts << account_two

        expect(document.payments).to eq [payment_one, payment_two]
      end
    end

    describe "#deductions" do
      it "returns deductions from all accounts" do
        document = Document.new
        account_one = Document::Account.new
        deduction_one = Document::Deduction.new
        account_one.deductions << deduction_one

        account_two = Document::Account.new
        deduction_two = Document::Deduction.new
        account_two.deductions << deduction_two

        document.accounts << account_one
        document.accounts << account_two

        expect(document.deductions).to eq [deduction_one, deduction_two]
      end
    end
  end
end
