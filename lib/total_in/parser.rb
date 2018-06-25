require "total_in/file_format_validator"
require "total_in/line_parsers"
require "total_in/document"

module TotalIn
  class InvalidFileFormatError < ArgumentError; end;

  class Parser
    LINE_TYPES = {
      0 => :document_start,
      99 => :document_end,
      10 => :account_start,
      90 => :account_end,
      20 => :payment_start,
      25 => :deduction_start,
      30 => :reference_numbers,
      40 => :messages,
      50 => :sender_start,
      51 => :sender_address,
      52 => :sender_locality,
      60 => :sender_account_start,
      61 => :sender_account_names,
      62 => :sender_account_address,
      63 => :sender_account_locality,
      70 => :international
    }.freeze

    attr_reader :file

    # Parser.new accepts a File instance or a String
    # A InvalidFileFormatError will be raised if file isn't in the TotalIn format
    def initialize file
      @file = file
      validate_file_format
    end

    ParseRunner = ->(parsers:, context:, iterator:) {
      loop do
        line_type, line = iterator.peek
        break unless parsers.key?(line_type)
        iterator.next

        context = parsers.fetch(line_type).call(line, context, iterator)
      end

      context
    }

    PARSERS = {
      document_start: ->(line, document, _) {
        document.assign_attributes(
          LineParsers::DocumentStart.new(line).attributes
        )
        document
      },
      account_start: ->(line, document, iterator) {
        document.accounts << AccountParser.call(line, iterator)
        document
      },
      payment_start: ->(line, account, iterator) {
        account.payments << PaymentParser.call(line, iterator)
        account
      },
      reference_numbers: ->(line, transaction, _) {
        transaction.reference_numbers.concat(
          LineParsers::ReferenceNumbers.new(line).values
        )
        transaction
      },
      messages: ->(line, transaction, _) {
        LineParsers::Messages.new(line).values.each do |message|
          transaction.add_message(message)
        end
        transaction
      },
      sender_start: ->(line, transaction, iterator) {
        transaction.sender = SenderParser.call(line, iterator)
        transaction
      },
      sender_address: ->(line, sender, _) {
        sender.address = LineParsers::Addresses.new(line).address
        sender
      },
      sender_locality: ->(line, sender, _) {
        sender.assign_attributes(
          LineParsers::Locality.new(line).attributes
        )
        sender
      },
      sender_account_start: ->(line, payment, iterator) {
        payment.sender_account = SenderAccountParser.call(line, iterator)
        payment
      },
      sender_account_names: ->(line, sender_account, _) {
        sender_account.name = LineParsers::Names.new(line).full_name
        sender_account
      },
      sender_account_address: ->(line, sender_account, _) {
        sender_account.address = LineParsers::Addresses.new(line).address
        sender_account
      },
      sender_account_locality: ->(line, sender_account, _) {
        sender_account.assign_attributes(
          LineParsers::Locality.new(line).attributes
        )
        sender_account
      },
      international: ->(line, transaction, _) {
        transaction.international = Document::International.new(
          LineParsers::International.new(line).attributes
        )
        transaction
      },
      deduction_start: ->(line, account, iterator) {
        account.deductions << DeductionParser.call(line, iterator)
        account
      },
      account_end: ->(line, account, _) {
        account.assign_attributes(
          LineParsers::AccountEnd.new(line).attributes
        )
        account
      },
      document_end: ->(line, document, _) {
        document.number_of_lines = LineParsers::DocumentEnd.new(line).number_of_lines
        document
      }
    }.freeze

    DocumentParser = ->(line_iterator) {
      ParseRunner.call(
        context: Document.new,
        iterator: line_iterator,
        parsers: PARSERS.slice(:document_start, :account_start, :document_end)
      )
    }

    AccountParser = ->(line, line_iterator) {
      account = Document::Account.new(LineParsers::AccountStart.new(line).attributes)

      ParseRunner.call(
        context: account,
        iterator: line_iterator,
        parsers: PARSERS.slice(:payment_start, :deduction_start, :account_end)
      )
    }

    PaymentParser = ->(line, line_iterator) {
      payment_line = LineParsers::PaymentStart.new(line)
      payment = Document::Payment.new(payment_line.attributes)
      payment.reference_numbers << payment_line.reference_number if payment_line.reference_number

      ParseRunner.call(
        context: payment,
        iterator: line_iterator,
        parsers: PARSERS.slice(
          :reference_numbers,
          :messages,
          :sender_start,
          :sender_account_start,
          :international
        )
      )
    }

    DeductionParser = ->(line, line_iterator) {
      deduction_line = LineParsers::DeductionStart.new(line)
      deduction = Document::Deduction.new(deduction_line.attributes)
      deduction.reference_numbers << deduction_line.reference_number if deduction_line.reference_number

      ParseRunner.call(
        context: deduction,
        iterator: line_iterator,
        parsers: PARSERS.slice(
          :reference_numbers,
          :messages,
          :sender_start,
          :sender_account_start,
          :international
        )
      )
    }

    SenderParser = ->(line, line_iterator) {
      sender = Document::Sender.new(name: LineParsers::Names.new(line).full_name )

      ParseRunner.call(
        context: sender,
        iterator: line_iterator,
        parsers: PARSERS.slice(:sender_address, :sender_locality)
      )
    }

    SenderAccountParser = ->(line, line_iterator) {
      sender_account = Document::SenderAccount.new(
        LineParsers::SenderAccountStart.new(line).attributes
      )

      ParseRunner.call(
        context: sender_account,
        iterator: line_iterator,
        parsers: PARSERS.slice(
          :sender_account_names,
          :sender_account_address,
          :sender_account_locality
        )
      )
    }

    def parse
      DocumentParser.call(lines.lazy.map { |l| tokenize_line(l) })
    end

    def result
      parse
    end

    protected

    def lines
      file.each_line
    end

    def validate_file_format
      validator = FileFormatValidator.new(first_line)

      unless validator.valid?
        raise InvalidFileFormatError.new(validator.errors.join(", "))
      end
    end

    def tokenize_line line
      line = line.encode(Encoding::UTF_8) if encode_lines?

      [line_type(line), line]
    end

    def line_type line
      LINE_TYPES.fetch(line[0..1].to_i)
    end

    def encode_lines?
      first_line.encoding != Encoding::UTF_8
    end

    def first_line
      @first_line ||= begin
        line = self.lines.peek
        self.lines.rewind # peek seems to move the pointer when file is an actual File object

        line
      end
    end
  end
end
