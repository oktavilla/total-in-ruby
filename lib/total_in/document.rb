require "total_in/attribute_methods"

module TotalIn
  class Document
    include AttributeMethods
    attribute :id
    attribute :created_at
    attribute :delivery_number
    attribute :file_type
    attribute :name
    attribute :number_of_lines

    def accounts
      @accounts ||= []
    end

    class Account
      include AttributeMethods
      attribute :account_number
      attribute :currency
      attribute :date
      attribute :number_of_transactions
      attribute :amount
      attribute :statement_reference

      def payments
        @payments ||= []
      end

      def deductions
        @deductions ||= []
      end
    end

    class Transaction
      include AttributeMethods
      def reference_numbers
        @reference_numbers ||= []
      end

      attr_accessor :sender
      attr_accessor :sender_account
      attr_accessor :international

      def message
        messages.join "\n" if messages.any?
      end

      def messages
        @messages ||= []
      end

      def add_message message
        messages.push message
      end

      def international?
        !!self.international
      end
    end

    class Payment < Transaction
      attribute :amount
      attribute :serial_number
      attribute :receiving_bankgiro_number
    end

    class Deduction < Transaction
      attribute :amount
      attribute :serial_number
      attribute :receiving_bankgiro_number
      attribute :code
    end

    class Sender
      include AttributeMethods
      attribute :name
      attribute :address
      attribute :postal_code
      attribute :city
      attribute :country_code

      def self.add_to_contexts contexts
        unless contexts.current.is_a?(self)
          until contexts.current.kind_of?(Transaction)
            contexts.move_up
          end

          entity = self.new

          setter_name = StringHelpers.underscore self.name.split("::").last
          contexts.current.public_send "#{setter_name}=", entity

          contexts.add entity
        end

        contexts
      end
    end

    class SenderAccount
      include AttributeMethods
      attribute :name
      attribute :address
      attribute :postal_code
      attribute :city
      attribute :country_code
      attribute :account_number
      attribute :origin_code
      attribute :company_organization_number

      def self.add_to_contexts contexts
        unless contexts.current.is_a?(self)
          until contexts.current.kind_of?(Transaction)
            contexts.move_up
          end

          entity = self.new

          setter_name = StringHelpers.underscore self.name.split("::").last
          contexts.current.public_send "#{setter_name}=", entity

          contexts.add entity
        end

        contexts
      end
    end

    class International
      include AttributeMethods
      attribute :cost
      attribute :cost_currency
      attribute :amount
      attribute :amount_currency
      attribute :exchange_rate
    end
  end
end
