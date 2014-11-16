require "total_in/line_parser"

module TotalIn
  module LineParsers
    class DocumentStart < LineParser
      field :id, 2..13
      field :created_at, 14..34, :time
    end

    class DocumentEnd < LineParser
      field :number_of_lines, 2..16, :integer
    end

    class AccountStart < LineParser
      field :number, 2..37
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

    class DecuctionStart < LineParser
      field :reference_number, 2..36
      field :amount, 37..51, :integer
      field :serial_number, 52..68, :integer
      field :code, 69..69
      field :receiving_bankgiro_number, 70..77
    end

    class ReferenceNumbers < LineParser
      field :reference_numbers, [2..36, 37..71]
    end

    class Messages < LineParser
      field :messages, [2..36, 37..71]
    end

    class Names < LineParser
      field :names, [2..36, 37..71]
    end

    class Addresses < LineParser
      field :addresses, [2..36, 37..71]
    end

    class Locality < LineParser
      field :postal_code, 2..10
      field :city, 11..45
      field :country_code, 46..47
    end

    class SenderAccount < LineParser
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
  end
end

