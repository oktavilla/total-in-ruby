require "total_in/line_parsers"
require "total_in/line_processors"

module TotalIn
  module LineHandlers
    Handler = Struct.new :parser, :processor do
      def handle line, contexts
        line_parser = self.parser.new(line)

        processor.call line_parser, contexts
      end
    end

    def self.document_start
      Handler.new LineParsers::DocumentStart, LineProcessors::DocumentStart
    end

    def self.document_end
      Handler.new LineParsers::DocumentEnd, LineProcessors::DocumentEnd
    end

    def self.account_start
      Handler.new LineParsers::AccountStart, LineProcessors::AccountStart
    end

    def self.account_end
      Handler.new LineParsers::AccountEnd, LineProcessors::AccountEnd
    end

    def self.payment_start
      Handler.new LineParsers::PaymentStart, LineProcessors::PaymentStart
    end

    def self.deduction_start
      Handler.new LineParsers::DeductionStart, LineProcessors::DeductionStart
    end

    def self.reference_numbers
      Handler.new LineParsers::ReferenceNumbers, LineProcessors::ReferenceNumbers
    end

    def self.messages
      Handler.new LineParsers::Messages, LineProcessors::Messages
    end

    def self.sender_names
      Handler.new LineParsers::Names, LineProcessors::Names.new(Document::Sender)
    end

    def self.sender_address
      Handler.new LineParsers::Addresses, LineProcessors::Addresses.new(Document::Sender)
    end

    def self.sender_locality
      Handler.new LineParsers::Locality, LineProcessors::Locality.new(Document::Sender)
    end

    def self.sender_account_start
      Handler.new LineParsers::SenderAccount, LineProcessors::SenderAccount
    end

    def self.sender_account_names
      Handler.new LineParsers::Names, LineProcessors::Names.new(Document::SenderAccount)
    end

    def self.sender_account_address
      Handler.new LineParsers::Addresses, LineProcessors::Addresses.new(Document::SenderAccount)
    end

    def self.sender_account_locality
      Handler.new LineParsers::Locality, LineProcessors::Locality.new(Document::SenderAccount)
    end

    def self.international
      Handler.new LineParsers::International, LineProcessors::International
    end

    def self.all
      {
        "00" => self.document_start,
        "99" => self.document_end,
        "10" => self.account_start,
        "90" => self.account_end,
        "20" => self.payment_start,
        "25" => self.deduction_start,
        "30" => self.reference_numbers,
        "40" => self.messages,
        "50" => self.sender_names,
        "51" => self.sender_address,
        "52" => self.sender_locality,
        "60" => self.sender_account_start,
        "61" => self.sender_account_names,
        "62" => self.sender_account_address,
        "63" => self.sender_account_locality,
        "70" => self.international
      }
    end
  end
end
