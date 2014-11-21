require "total_in/string_helpers"
require "total_in/line_parsers"
require "total_in/document"

module TotalIn
  class Parser
    def self.parsers
      @parsers ||= {}
    end

    def self.register_parser identifier, parser_class, transformer
      parsers[identifier] = [parser_class, transformer]
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
      if line = lines.shift
        parse_lines lines, parse_line(line, contexts)
      else
        contexts
      end
    end

    def parse_line line, contexts
      parser, transformer = parser_for_line(line)

      transformer.call parser.new(line), contexts
    end

    def parser_for_line line
      self.class.parsers.fetch line[0..1]
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


  TotalIn::Parser.register_parser "00", LineParsers::DocumentStart, ->(line, contexts) {
    document = Document.new line.attributes

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

    account = Document::Account.new line.attributes

    contexts.current.accounts << account
    contexts.add account

    contexts
  }

  TotalIn::Parser.register_parser "90", LineParsers::AccountEnd, ->(line, contexts) {
    contexts.move_to Document::Account

    contexts.current.assign_attributes line.attributes

    contexts
  }

  TotalIn::Parser.register_parser "20", LineParsers::PaymentStart, ->(line, contexts) {
    contexts.move_to Document::Account

    payment = Document::Payment.new line.attributes
    payment.reference_numbers << line.reference_number if line.reference_number

    contexts.current.payments << payment

    contexts.add payment

    contexts
  }

  TotalIn::Parser.register_parser "25", LineParsers::DeductionStart, ->(line, contexts) {
    contexts.move_to Document::Account

    deduction = Document::Deduction.new line.attributes
    deduction.reference_numbers << line.reference_number if line.reference_number

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
    contexts = Document::Sender.add_to_contexts contexts

    contexts.current.name = line.values.join " "

    contexts
  }

  TotalIn::Parser.register_parser "51", LineParsers::Addresses, ->(line, contexts) {
    contexts = Document::Sender.add_to_contexts contexts

    contexts.current.address = line.values.join " "

    contexts
  }

  TotalIn::Parser.register_parser "52", LineParsers::Locality, ->(line, contexts) {
    contexts = Document::Sender.add_to_contexts contexts

    contexts.current.assign_attributes line.attributes

    contexts
  }

  TotalIn::Parser.register_parser "60", LineParsers::SenderAccount, ->(line, contexts) {
    contexts = Document::SenderAccount.add_to_contexts contexts

    contexts.current.assign_attributes line.attributes

    contexts
  }

  TotalIn::Parser.register_parser "61", LineParsers::Names, ->(line, contexts) {
    contexts = Document::SenderAccount.add_to_contexts contexts

    contexts.current.name = line.values.join " "

    contexts
  }

  TotalIn::Parser.register_parser "62", LineParsers::Addresses, ->(line, contexts) {
    contexts = Document::SenderAccount.add_to_contexts contexts

    contexts.current.address = line.values.join " "

    contexts
  }

  TotalIn::Parser.register_parser "63", LineParsers::Locality, ->(line, contexts) {
    contexts = Document::SenderAccount.add_to_contexts contexts

    contexts.current.assign_attributes line.attributes

    contexts
  }

  TotalIn::Parser.register_parser "70", LineParsers::International, ->(line, contexts) {
    until contexts.current.kind_of?(Document::Transaction)
      contexts.move_up
    end

    international = Document::International.new line.attributes

    contexts.current.international = international

    contexts
  }
end
