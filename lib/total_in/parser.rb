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
      results = parse_lines text.each_line.to_a, [Result.new]

      results.first
    end

    def parse_lines lines, contexts
      while line_string = lines.shift
        line_parser, transformer = *self.class.parser_for_line(line_string)

        contexts = transformer.call line_parser.new(line_string), contexts
        parse_lines lines, contexts
      end

      contexts
    end

  end

  class Result
    attr_accessor :report_id, :created_at, :number_of_lines

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
      unless contexts.last.is_a?(self)
        until contexts.last.kind_of?(Transaction)
          contexts.pop
        end

        entity = self.new

        setter_name = StringHelpers.underscore self.name.split("::").last
        contexts.last.public_send "#{setter_name}=", entity

        contexts.push entity
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

    def self.field name, position_range, type = :string
      define_method name do
        value = line[position_range].strip
        Typecaster.cast value, type
      end
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
    contexts.last.report_id = line.id
    contexts.last.created_at = line.created_at

    contexts
  }

  class DocumentEndLine < LineParser
    field :number_of_lines, 2..16, :integer
  end

  TotalIn::Parser.register_parser "99", DocumentEndLine, ->(line, contexts) {
    contexts.last.number_of_lines = line.number_of_lines

    contexts
  }

  class AccountStartLine < LineParser
    field :number, 2..37
    field :currency, 38..40
    field :date, 41..48, :date
  end

  TotalIn::Parser.register_parser "10", AccountStartLine, ->(line, contexts) {
    account = Account.new
    account.account_number = line.number
    account.currency = line.currency
    account.date = line.date

    contexts.last.accounts << account
    contexts.push account

    contexts
  }

  class AccountEndLine < LineParser
    field :number_of_transactions, 2..9, :integer
    field :amount, 10..26, :integer
    field :statement_reference, 27..37
  end

  TotalIn::Parser.register_parser "90", AccountEndLine, ->(line, contexts) {
    until contexts.last.is_a?(Account)
      contexts.pop
    end

    contexts.last.number_of_transactions = line.number_of_transactions
    contexts.last.amount = line.amount
    contexts.last.statement_reference = line.statement_reference

    until contexts.last.is_a?(Result)
      contexts.pop
    end

    contexts
  }

  class PaymentStartLine < LineParser
    field :reference_number, 2..36
    field :amount, 37..51, :integer
    field :serial_number, 52..68, :integer
    field :receiving_bankgiro_number, 69..76
  end

  TotalIn::Parser.register_parser "20", PaymentStartLine, ->(line, contexts) {
    until contexts.last.is_a?(Account)
      contexts.pop
    end

    payment = Payment.new

    payment.reference_numbers << line.reference_number unless line.reference_number.to_i.zero?
    payment.amount = line.amount
    payment.serial_number = line.serial_number
    payment.receiving_bankgiro_number = payment.receiving_bankgiro_number

    contexts.last.payments << payment

    contexts.push payment

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
    until contexts.last.is_a?(Account)
      contexts.pop
    end

    deduction = Deduction.new

    deduction.reference_numbers << line.reference_number unless line.reference_number.to_i.zero?
    deduction.amount = line.amount
    deduction.serial_number = line.serial_number
    deduction.receiving_bankgiro_number = line.receiving_bankgiro_number
    deduction.code = line.code

    contexts.last.deductions << deduction

    contexts.push deduction

    contexts
  }

  class ReferenceNumbersLine < LineParser
    field :first_reference_number, 2..36
    field :second_reference_number, 37..71
  end

  TotalIn::Parser.register_parser "30", ReferenceNumbersLine, ->(line, contexts) {
    contexts.last.reference_numbers.concat [
      line.first_reference_number,
      line.second_reference_number
    ].compact

    contexts
  }

  class MessageLine < LineParser
    field :first_message, 2..36
    field :second_message, 37..71
  end

  TotalIn::Parser.register_parser "40", MessageLine, ->(line, contexts) {
    [ line.first_message, line.second_message ].compact.each do |message|
      contexts.last.add_message message
    end

    contexts
  }

  class NameLine < LineParser
    field :first_name, 2..36
    field :last_name, 37..71
  end

  TotalIn::Parser.register_parser "50", NameLine, ->(line, contexts) {
    contexts = Sender.add_to_contexts contexts

    contexts.last.name = [
      line.first_name,
      line.last_name
    ].compact.join(" ")

    contexts
  }

  class AddressLine < LineParser
    field :first_address, 2..36
    field :second_address, 37..71
  end

  TotalIn::Parser.register_parser "51", AddressLine, ->(line, contexts) {
    contexts = Sender.add_to_contexts contexts

    contexts.last.address = [
      line.first_address,
      line.second_address
    ].compact.join(" ")

    contexts
  }

  class LocalityLine < LineParser
    field :postal_code, 2..10
    field :city, 11..45
    field :country_code, 46..47
  end

  TotalIn::Parser.register_parser "52", LocalityLine, ->(line, contexts) {
    contexts = Sender.add_to_contexts contexts

    contexts.last.postal_code = line.postal_code
    contexts.last.city = line.city
    contexts.last.country_code = line.country_code

    contexts
  }

  class SenderAccountLine < LineParser
    field :account_number, 2..37
    field :origin_code, 38..38, :integer
    field :company_organization_number, 39..58
  end

  TotalIn::Parser.register_parser "60", SenderAccountLine, ->(line, contexts) {
    contexts = SenderAccount.add_to_contexts contexts

    contexts.last.account_number = line.account_number
    contexts.last.origin_code = line.origin_code
    contexts.last.company_organization_number = line.company_organization_number

    contexts
  }

  TotalIn::Parser.register_parser "61", NameLine, ->(line, contexts) {
    contexts = SenderAccount.add_to_contexts contexts

    contexts.last.name = [
      line.first_name,
      line.last_name
    ].compact.join(" ")

    contexts
  }

  TotalIn::Parser.register_parser "62", AddressLine, ->(line, contexts) {
    contexts = SenderAccount.add_to_contexts contexts

    contexts.last.address = [
      line.first_address,
      line.second_address
    ].compact.join(" ")

    contexts
  }

  TotalIn::Parser.register_parser "63", LocalityLine, ->(line, contexts) {
    contexts = SenderAccount.add_to_contexts contexts

    contexts.last.postal_code = line.postal_code
    contexts.last.city = line.city
    contexts.last.country_code = line.country_code

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
    until contexts.last.kind_of?(Transaction)
      contexts.pop
    end

    international = International.new
    international.cost = line.cost
    international.cost_currency = line.cost_currency
    international.amount = line.amount
    international.amount_currency = line.amount_currency
    international.exchange_rate = line.exchange_rate

    contexts.last.international = international

    contexts
  }
end
