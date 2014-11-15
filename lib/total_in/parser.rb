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

    def self.register_parser identifier, parser
      parsers[identifier] = parser
    end

    def self.parser_for_line line
      identifier = line[0..1]
      self.parsers[identifier] || NullLineParser
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
      while line = lines.shift
        contexts = self.class.parser_for_line(line).call line, contexts
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

  class NullLineParser
    def self.call line, context
      context
    end
  end

  class LineParser
    attr_reader :line
    def initialize line
      @line = line
    end
  end

  class DocumentStartLine < LineParser
    def self.call line, contexts
      document_line = self.new line

      contexts.last.report_id = document_line.id
      contexts.last.created_at = document_line.created_at

      contexts
    end

    def id
      line[2..13].strip
    end

    def created_at
      Time.parse line[14..34]
    end

    TotalIn::Parser.register_parser "00", self
  end

  class DocumentEndLine
    def self.call line, contexts
      contexts.first.number_of_lines = line[2..16].strip.to_i

      context
    end

    TotalIn::Parser.register_parser "99", self
  end

  class AccountStartLine < LineParser
    def self.call line, contexts
      account_line = self.new line

      account = Account.new
      account.account_number = account_line.number
      account.currency = account_line.currency
      account.date = account_line.date

      contexts.last.accounts << account
      contexts.push account

      contexts
    end

    def number
      line[2..37].strip
    end

    def currency
      line[38..40]
    end

    def date
      Date.parse line[41..48]
    end

    TotalIn::Parser.register_parser "10", self
  end

  class AccountEndLine < LineParser
    def self.call line, contexts
      until contexts.last.is_a?(Account)
        contexts.pop
      end

      line_parser = self.new line

      contexts.last.number_of_transactions = line_parser.number_of_transactions
      contexts.last.amount = line_parser.amount
      contexts.last.statement_reference = line_parser.statement_reference

      until contexts.last.is_a?(Result)
        contexts.pop
      end

      contexts
    end

    def number_of_transactions
      line[2..9].to_i
    end

    def amount
      line[10..26].to_i
    end

    def statement_reference
      line[27..37].strip
    end

    TotalIn::Parser.register_parser "90", self
  end

  class TransactionLineParser < LineParser
    def reference_number
      line[2..36].strip
    end

    def amount
      line[37..51].to_i
    end

    def serial_number
      line[52..68].to_i
    end

    def receiving_bankgiro_number
      line[69..76].strip
    end
  end

  class PaymentRecordStartLine < TransactionLineParser
    def self.call line, contexts
      payment_line = self.new line

      until contexts.last.is_a?(Account)
        contexts.pop
      end

      payment = Payment.new
      unless payment_line.reference_number.to_i.zero?
        payment.reference_numbers << payment_line.reference_number
      end
      payment.amount = payment_line.amount
      payment.serial_number = payment_line.serial_number
      payment.receiving_bankgiro_number = payment.receiving_bankgiro_number

      contexts.last.payments << payment

      contexts.push payment

      contexts
    end

    TotalIn::Parser.register_parser "20", self
  end

  class DecuctionReordStartLine < TransactionLineParser
    def self.call line, contexts
      deduction_line = self.new line

      until contexts.last.is_a?(Account)
        contexts.pop
      end

      deduction = Deduction.new
      unless deduction_line.reference_number.to_i.zero?
        deduction.reference_numbers << deduction_line.reference_number
      end
      deduction.amount = deduction_line.amount
      deduction.serial_number = deduction_line.serial_number
      deduction.receiving_bankgiro_number = deduction_line.receiving_bankgiro_number

      contexts.last.deductions << deduction

      contexts.push deduction

      contexts
    end

    def code
      line[69..69]
    end

    def receiving_bankgiro_number
      line[70..77].strip
    end

    TotalIn::Parser.register_parser "25", self
  end

  class ReferenceNumbersLine
    def self.call line, contexts
      contexts.last.reference_numbers.concat [
        line[2..36].strip,
        line[37..71].strip
      ].find_all { |m| m != "" }

      contexts
    end

    TotalIn::Parser.register_parser "30", self
  end

  class MessageLine
    def self.call line, contexts
      [ line[2..36].strip, line[37..71].strip ].find_all { |m| m != "" }.each do |message|
        contexts.last.add_message message
      end

      contexts
    end

    TotalIn::Parser.register_parser "40", self
  end

  class NameLine
    def self.call line, contexts
      contexts = Sender.add_to_contexts contexts

      contexts.last.name = [
        line[2..36].strip,
        line[37..71].strip
      ].find_all { |m| m != "" }.join(" ")

      contexts
    end

    TotalIn::Parser.register_parser "50", self
  end

  class AddressLine
    def self.call line, contexts
      contexts = Sender.add_to_contexts contexts

      contexts.last.address = [
        line[2..36].strip,
        line[37..71].strip
      ].find_all { |m| m != "" }.join(" ")

      contexts
    end

    TotalIn::Parser.register_parser "51", self
  end

  class LocalityLine < LineParser
    def self.call line, contexts
      contexts = Sender.add_to_contexts contexts
      line_parser = self.new line

      contexts.last.postal_code = line_parser.postal_code
      contexts.last.city = line_parser.city
      contexts.last.country_code = line_parser.country_code

      contexts
    end

    def postal_code
      line[2..10].strip
    end

    def city
      line[11..45].strip
    end

    def country_code
      line[46..47].strip
    end

    TotalIn::Parser.register_parser "52", self
  end

  class SenderAccountLine < LineParser
    def self.call line, contexts
      contexts = SenderAccount.add_to_contexts contexts
      line_parser = self.new line

      contexts.last.account_number = line_parser.account_number
      contexts.last.origin_code = line_parser.origin_code
      contexts.last.company_organization_number = line_parser.company_organization_number

      contexts
    end

    def account_number
      line[2..37].strip
    end

    def origin_code
      code = line[38..38].strip.to_i
      code unless code.zero?
    end

    def company_organization_number
      number = line[39..58].strip
      number unless number == ""
    end

    TotalIn::Parser.register_parser "60", self
  end

  class SenderAccountNameLine
    def self.call line, contexts
      contexts = SenderAccount.add_to_contexts contexts

      contexts.last.name = [
        line[2..36].strip,
        line[37..71].strip
      ].find_all { |m| m != "" }.join(" ")

      contexts
    end

    TotalIn::Parser.register_parser "61", self
  end

  class SenderAccountAddressLine
    def self.call line, contexts
      contexts = SenderAccount.add_to_contexts contexts

      contexts.last.address = [
        line[2..36].strip,
        line[37..71].strip
      ].find_all { |m| m != "" }.join(" ")

      contexts
    end

    TotalIn::Parser.register_parser "62", self
  end

  class SenderAccountLocalityLine < LineParser
    def self.call line, contexts
      contexts = SenderAccount.add_to_contexts contexts
      line_parser = self.new line

      contexts.last.postal_code = line_parser.postal_code
      contexts.last.city = line_parser.city
      contexts.last.country_code = line_parser.country_code

      contexts
    end

    def postal_code
      line[2..10].strip
    end

    def city
      line[11..45].strip
    end

    def country_code
      line[46..47].strip
    end

    TotalIn::Parser.register_parser "63", self
  end

  class InternationalLine < LineParser
    def self.call line, contexts
      until contexts.last.kind_of?(Transaction)
        contexts.pop
      end

      international_line = self.new line

      international = International.new
      international.cost = international_line.cost
      international.cost_currency = international_line.cost_currency
      international.amount = international_line.amount
      international.amount_currency = international_line.amount_currency
      international.exchange_rate = international_line.exchange_rate

      contexts.last.international = international

      contexts
    end

    def cost
      line[2..16].to_i
    end

    def cost_currency
      currency = line[17..19].strip
      currency unless currency == ""
    end

    def amount
      line[38..52].to_i
    end

    def amount_currency
      currency = line[53..55].strip
      currency unless currency == ""
    end

    def exchange_rate
      line[56..67].to_i
    end

    TotalIn::Parser.register_parser "70", self
  end
end
