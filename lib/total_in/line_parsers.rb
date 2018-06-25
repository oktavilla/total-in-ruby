require "total_in/line_parser"

module TotalIn
  module LineParsers

    class DocumentStart < LineParser
      field :id, 2..13
      field :created_at, 14..33, :time
      field :delivery_number, 34..35, :integer
      field :file_type, 36..38
      field :name, 39..48
    end

    class DocumentEnd < LineParser
      field :number_of_lines, 2..16, :integer
    end

    class AccountStart < LineParser
      field :account_number, 2..37
      field :currency, 38..40
      field :date, 41..48, :date
    end

    class AccountEnd < LineParser
      field :number_of_transactions, 2..9, :integer
      field :amount, 10..26, :integer
      field :statement_reference, 27..37
    end

    class PaymentStart < LineParser
      field :reference_number, 2..36
      field :amount, 37..51, :integer
      field :serial_number, 52..68, :integer
      field :receiving_bankgiro_number, 69..76
    end

    class DeductionStart < LineParser
      field :reference_number, 2..36
      field :amount, 37..51, :integer
      field :serial_number, 52..68, :integer
      field :code, 69..69, :integer
      field :receiving_bankgiro_number, 70..77
    end

    class Values < LineParser
      field :values, [2..36, 37..71]
    end

    class ReferenceNumbers < Values
    end

    class Messages < Values
    end

    class Names < Values
      def full_name
        values.join(" ")
      end
    end

    class Addresses < Values
      def address
        values.join(" ")
      end
    end

    class Locality < LineParser
      field :postal_code, 2..10
      field :city, 11..45
      field :country_code, 46..47
    end

    class SenderAccountStart < LineParser
      field :account_number, 2..37
      field :origin_code, 38..38, :integer
      field :company_organization_number, 39..58
    end

    class International < LineParser
      field :cost, 2..16, :integer
      field :cost_currency, 17..19
      field :amount, 38..52, :integer
      field :amount_currency, 53..55
      field :exchange_rate, 56..67, :integer
    end

    PARSERS = {
      document_start: DocumentStart,
      account_start: AccountStart,
      payment_start: PaymentStart,
      deduction_start: DeductionStart,
      reference_numbers: ReferenceNumbers,
      messages: Messages,
      sender_start: Names,
      sender_address: Addresses,
      sender_locality: Locality,
      sender_account_start: SenderAccountStart,
      sender_account_names: Names,
      sender_account_address: Addresses,
      sender_account_locality: Locality,
      international: International,
      account_end: AccountEnd,
      document_end: DocumentEnd
    }

    def self.parser_for_type type
      PARSERS.fetch(type)
    end
  end
end
