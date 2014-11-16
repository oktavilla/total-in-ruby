require "total_in/string_helpers"
require "total_in/line_parsers"

module TotalIn
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
    attr_accessor :delivery_number
    attr_accessor :file_type
    attr_accessor :name
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

  TotalIn::Parser.register_parser "00", LineParsers::DocumentStart, ->(line, contexts) {
    document = Document.new
    document.report_id = line.id
    document.created_at = line.created_at
    document.delivery_number = line.delivery_number
    document.file_type = line.file_type
    document.name = line.name

    contexts.add document

    contexts
  }

  TotalIn::Parser.register_parser "99", LineParsers::DocumentEnd, ->(line, contexts) {
    contexts.move_to Document

    contexts.current.number_of_lines = line.number_of_lines

    contexts
  }

  TotalIn::Parser.register_parser "10", LineParsers::AccountStart, ->(line, contexts) {
    contexts.move_to Document

    account = Account.new
    account.account_number = line.number
    account.currency = line.currency
    account.date = line.date

    contexts.current.accounts << account
    contexts.add account

    contexts
  }

  TotalIn::Parser.register_parser "90", LineParsers::AccountEnd, ->(line, contexts) {
    contexts.move_to Account

    contexts.current.number_of_transactions = line.number_of_transactions
    contexts.current.amount = line.amount
    contexts.current.statement_reference = line.statement_reference

    contexts
  }

  TotalIn::Parser.register_parser "20", LineParsers::PaymentStart, ->(line, contexts) {
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

  TotalIn::Parser.register_parser "25", LineParsers::DeductionStart, ->(line, contexts) {
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

  TotalIn::Parser.register_parser "30", LineParsers::ReferenceNumbers, ->(line, contexts) {
    contexts.current.reference_numbers.concat line.values

    contexts
  }

  TotalIn::Parser.register_parser "40", LineParsers::Messages, ->(line, contexts) {
    line.values.each do |message|
      contexts.current.add_message message
    end

    contexts
  }

  TotalIn::Parser.register_parser "50", LineParsers::Names, ->(line, contexts) {
    contexts = Sender.add_to_contexts contexts

    contexts.current.name = line.values.join " "

    contexts
  }

  TotalIn::Parser.register_parser "51", LineParsers::Addresses, ->(line, contexts) {
    contexts = Sender.add_to_contexts contexts

    contexts.current.address = line.values.join " "

    contexts
  }

  TotalIn::Parser.register_parser "52", LineParsers::Locality, ->(line, contexts) {
    contexts = Sender.add_to_contexts contexts

    contexts.current.postal_code = line.postal_code
    contexts.current.city = line.city
    contexts.current.country_code = line.country_code

    contexts
  }

  TotalIn::Parser.register_parser "60", LineParsers::SenderAccount, ->(line, contexts) {
    contexts = TotalIn::SenderAccount.add_to_contexts contexts

    contexts.current.account_number = line.account_number
    contexts.current.origin_code = line.origin_code
    contexts.current.company_organization_number = line.company_organization_number

    contexts
  }

  TotalIn::Parser.register_parser "61", LineParsers::Names, ->(line, contexts) {
    contexts = TotalIn::SenderAccount.add_to_contexts contexts

    contexts.current.name = line.values.join " "

    contexts
  }

  TotalIn::Parser.register_parser "62", LineParsers::Addresses, ->(line, contexts) {
    contexts = TotalIn::SenderAccount.add_to_contexts contexts

    contexts.current.address = line.values.join " "

    contexts
  }

  TotalIn::Parser.register_parser "63", LineParsers::Locality, ->(line, contexts) {
    contexts = TotalIn::SenderAccount.add_to_contexts contexts

    contexts.current.postal_code = line.postal_code
    contexts.current.city = line.city
    contexts.current.country_code = line.country_code

    contexts
  }

  TotalIn::Parser.register_parser "70", LineParsers::International, ->(line, contexts) {
    until contexts.current.kind_of?(Transaction)
      contexts.move_up
    end

    international = TotalIn::International.new
    international.cost = line.cost
    international.cost_currency = line.cost_currency
    international.amount = line.amount
    international.amount_currency = line.amount_currency
    international.exchange_rate = line.exchange_rate

    contexts.current.international = international

    contexts
  }
end
