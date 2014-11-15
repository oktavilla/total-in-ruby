module TotalIn
  module StringHelpers
    def self.underscore word
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase
    end
  end

  class Parser
    def self.parsers
      @parsers ||= {}
    end

    def self.register_parser identifier, parser_class, transformer
      parsers[identifier] = [parser_class, transformer]
    end

    def self.parser_for_line line
      parsers.fetch line[0..1]
    end

    attr_reader :text
    def initialize text
      @text = text
    end

    def result
      contexts = parse_lines text.each_line.to_a, Contexts.new

      contexts.result
    end

    private

    def parse_lines lines, contexts
      while line_string = lines.shift
        line_parser, transformer = self.class.parser_for_line(line_string)

        contexts = transformer.call line_parser.new(line_string), contexts
        parse_lines lines, contexts
      end

      contexts
    end

    class Contexts
      def result
        contexts.first
      end

      def current
        contexts.last
      end

      def add container
        contexts.push container
      end

      def move_up
        contexts.pop
      end

      def move_to container_class
        until current.is_a?(container_class)
          move_up
        end
      end

      private

      def contexts
        @contexts ||= []
      end
    end
  end

  class Document
    attr_accessor :report_id
    attr_accessor :created_at
    attr_accessor :number_of_lines

    def accounts
      @accounts ||= []
    end
  end

  class Account
    attr_accessor :account_number
    attr_accessor :currency
    attr_accessor :date
    attr_accessor :number_of_transactions
    attr_accessor :amount
    attr_accessor :statement_reference

    def payments
      @payments ||= []
    end

    def deductions
      @deductions ||= []
    end
  end

  class Transaction
    def reference_numbers
      @reference_numbers ||= []
    end

    attr_accessor :amount
    attr_accessor :serial_number
    attr_accessor :sender
    attr_accessor :sender_account
    attr_accessor :receiving_bankgiro_number

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

    attr_accessor :international
  end

  class Payment < Transaction
  end

  class Deduction < Transaction
    attr_accessor :code
  end

  class Entity
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

    attr_accessor :name
    attr_accessor :address
    attr_accessor :postal_code
    attr_accessor :city
    attr_accessor :country_code
  end

  class Sender < Entity
  end

  class SenderAccount < Entity
    attr_accessor :account_number
    attr_accessor :origin_code
    attr_accessor :company_organization_number
  end

  class International
    attr_accessor :cost
    attr_accessor :cost_currency
    attr_accessor :amount
    attr_accessor :amount_currency
    attr_accessor :exchange_rate
  end

  class LineParser
    attr_reader :line
    def initialize line
      @line = line
    end

    def self.field name, range, type = :string
      define_method name do
        if range.is_a?(Array)
          range.map { |r| value_at_position(r, type) }.compact
        else
          value_at_position range, type
        end
      end
    end

    private

    def value_at_position range, type
      typecast line[range].strip, type
    end

    def typecast value, type
      Typecaster.cast value, type
    end
  end

  module Typecaster
    def self.cast value, type
      casters.fetch(type).call(value) unless value == ""
    end

    def self.casters
      {
        integer: ->(value) { value.to_i },
        time: ->(value) { Time.parse(value) },
        date: ->(value) { Date.parse(value) },
        string: ->(value) { value }
      }
    end
  end

  class DocumentStartLine < LineParser
    field :id, 2..13
    field :created_at, 14..34, :time
  end

  TotalIn::Parser.register_parser "00", DocumentStartLine, ->(line, contexts) {
    document = Document.new
    document.report_id = line.id
    document.created_at = line.created_at

    contexts.add document

    contexts
  }

  class DocumentEndLine < LineParser
    field :number_of_lines, 2..16, :integer
  end

  TotalIn::Parser.register_parser "99", DocumentEndLine, ->(line, contexts) {
    contexts.move_to Document

    contexts.current.number_of_lines = line.number_of_lines

    contexts
  }

  class AccountStartLine < LineParser
    field :number, 2..37
    field :currency, 38..40
    field :date, 41..48, :date
  end

  TotalIn::Parser.register_parser "10", AccountStartLine, ->(line, contexts) {
    contexts.move_to Document

    account = Account.new
    account.account_number = line.number
    account.currency = line.currency
    account.date = line.date

    contexts.current.accounts << account
    contexts.add account

    contexts
  }

  class AccountEndLine < LineParser
    field :number_of_transactions, 2..9, :integer
    field :amount, 10..26, :integer
    field :statement_reference, 27..37
  end

  TotalIn::Parser.register_parser "90", AccountEndLine, ->(line, contexts) {
    contexts.move_to Account

    contexts.current.number_of_transactions = line.number_of_transactions
    contexts.current.amount = line.amount
    contexts.current.statement_reference = line.statement_reference

    contexts
  }

  class PaymentStartLine < LineParser
    field :reference_number, 2..36
    field :amount, 37..51, :integer
    field :serial_number, 52..68, :integer
    field :receiving_bankgiro_number, 69..76
  end

  TotalIn::Parser.register_parser "20", PaymentStartLine, ->(line, contexts) {
    contexts.move_to Account

    payment = Payment.new

    payment.reference_numbers << line.reference_number unless line.reference_number.to_i.zero?
    payment.amount = line.amount
    payment.serial_number = line.serial_number
    payment.receiving_bankgiro_number = payment.receiving_bankgiro_number

    contexts.current.payments << payment

    contexts.add payment

    contexts
  }

  class DecuctionStartLine < LineParser
    field :reference_number, 2..36
    field :amount, 37..51, :integer
    field :serial_number, 52..68, :integer
    field :code, 69..69
    field :receiving_bankgiro_number, 70..77
  end

  TotalIn::Parser.register_parser "25", DecuctionStartLine, ->(line, contexts) {
    contexts.move_to Account

    deduction = Deduction.new

    deduction.reference_numbers << line.reference_number unless line.reference_number.to_i.zero?
    deduction.amount = line.amount
    deduction.serial_number = line.serial_number
    deduction.receiving_bankgiro_number = line.receiving_bankgiro_number
    deduction.code = line.code

    contexts.current.deductions << deduction

    contexts.add deduction

    contexts
  }

  class ReferenceNumbersLine < LineParser
    field :reference_numbers, [2..36, 37..71]
  end

  TotalIn::Parser.register_parser "30", ReferenceNumbersLine, ->(line, contexts) {
    contexts.current.reference_numbers.concat line.reference_numbers

    contexts
  }

  class MessageLine < LineParser
    field :messages, [2..36, 37..71]
  end

  TotalIn::Parser.register_parser "40", MessageLine, ->(line, contexts) {
    line.messages.each do |message|
      contexts.current.add_message message
    end

    contexts
  }

  class NameLine < LineParser
    field :names, [2..36, 37..71]
  end

  TotalIn::Parser.register_parser "50", NameLine, ->(line, contexts) {
    contexts = Sender.add_to_contexts contexts

    contexts.current.name = line.names.join " "

    contexts
  }

  class AddressLine < LineParser
    field :addresses, [2..36, 37..71]
  end

  TotalIn::Parser.register_parser "51", AddressLine, ->(line, contexts) {
    contexts = Sender.add_to_contexts contexts

    contexts.current.address = line.addresses.join " "

    contexts
  }

  class LocalityLine < LineParser
    field :postal_code, 2..10
    field :city, 11..45
    field :country_code, 46..47
  end

  TotalIn::Parser.register_parser "52", LocalityLine, ->(line, contexts) {
    contexts = Sender.add_to_contexts contexts

    contexts.current.postal_code = line.postal_code
    contexts.current.city = line.city
    contexts.current.country_code = line.country_code

    contexts
  }

  class SenderAccountLine < LineParser
    field :account_number, 2..37
    field :origin_code, 38..38, :integer
    field :company_organization_number, 39..58
  end

  TotalIn::Parser.register_parser "60", SenderAccountLine, ->(line, contexts) {
    contexts = SenderAccount.add_to_contexts contexts

    contexts.current.account_number = line.account_number
    contexts.current.origin_code = line.origin_code
    contexts.current.company_organization_number = line.company_organization_number

    contexts
  }

  TotalIn::Parser.register_parser "61", NameLine, ->(line, contexts) {
    contexts = SenderAccount.add_to_contexts contexts

    contexts.current.name = line.names.join " "

    contexts
  }

  TotalIn::Parser.register_parser "62", AddressLine, ->(line, contexts) {
    contexts = SenderAccount.add_to_contexts contexts

    contexts.current.address = line.addresses.join " "

    contexts
  }

  TotalIn::Parser.register_parser "63", LocalityLine, ->(line, contexts) {
    contexts = SenderAccount.add_to_contexts contexts

    contexts.current.postal_code = line.postal_code
    contexts.current.city = line.city
    contexts.current.country_code = line.country_code

    contexts
  }

  class InternationalLine < LineParser
    field :cost, 2..16, :integer
    field :cost_currency, 17..19
    field :amount, 38..52, :integer
    field :amount_currency, 53..55
    field :exchange_rate, 56..67, :integer
  end

  TotalIn::Parser.register_parser "70", InternationalLine, ->(line, contexts) {
    until contexts.current.kind_of?(Transaction)
      contexts.move_up
    end

    international = International.new
    international.cost = line.cost
    international.cost_currency = line.cost_currency
    international.amount = line.amount
    international.amount_currency = line.amount_currency
    international.exchange_rate = line.exchange_rate

    contexts.current.international = international

    contexts
  }
end
