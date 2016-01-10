require "total_in/document"

module TotalIn
  module LineProcessors
    DocumentStart = ->(line, contexts) {
      document = Document.new line.attributes

      contexts.add document

      contexts
    }

    DocumentEnd = ->(line, contexts) {
      contexts.move_to Document

      contexts.current.number_of_lines = line.number_of_lines

      contexts
    }

    AccountStart = ->(line, contexts) {
      contexts.move_to Document

      account = Document::Account.new line.attributes

      contexts.current.accounts << account
      contexts.add account

      contexts
    }

    AccountEnd = ->(line, contexts) {
      contexts.move_to Document::Account

      contexts.current.assign_attributes line.attributes

      contexts
    }

    PaymentStart = ->(line, contexts) {
      contexts.move_to Document::Account

      payment = Document::Payment.new line.attributes
      payment.reference_numbers << line.reference_number if line.reference_number

      contexts.current.payments << payment

      contexts.add payment

      contexts
    }

    DeductionStart = ->(line, contexts) {
      contexts.move_to Document::Account

      deduction = Document::Deduction.new line.attributes
      deduction.reference_numbers << line.reference_number if line.reference_number

      contexts.current.deductions << deduction
      contexts.add deduction

      contexts
    }

    ReferenceNumbers = ->(line, contexts) {
      contexts.current.reference_numbers.concat line.values

      contexts
    }

    Messages = ->(line, contexts) {
      line.values.each do |message|
        contexts.current.add_message message
      end

      contexts
    }

    class WithTargetClass
      attr_reader :target_class

      def initialize target_class
        @target_class = target_class
      end
    end

    class Names < WithTargetClass
      def call line, contexts
        contexts.move_to_or_add_to_parent self.target_class, Document::Transaction

        contexts.current.name = line.values.join " "

        contexts
      end
    end

    class Addresses < WithTargetClass
      def call line, contexts
        contexts.move_to_or_add_to_parent self.target_class, Document::Transaction

        contexts.current.address = line.values.join " "

        contexts
      end
    end

    class Locality < WithTargetClass
      def call line, contexts
        contexts.move_to_or_add_to_parent self.target_class, Document::Transaction

        contexts.current.assign_attributes line.attributes

        contexts
      end
    end

    SenderAccount = ->(line, contexts) {
      contexts.move_to_or_add_to_parent Document::SenderAccount, Document::Transaction

      contexts.current.assign_attributes line.attributes

      contexts
    }

    International = ->(line, contexts) {
      contexts.move_to Document::Transaction

      international = Document::International.new line.attributes

      contexts.current.international = international

      contexts
    }
  end
end
