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

    def self.all
      {
        "00" => Handler.new(LineParsers::DocumentStart, LineProcessors::DocumentStart),
        "99" => Handler.new(LineParsers::DocumentEnd, LineProcessors::DocumentEnd),
        "10" => Handler.new(LineParsers::AccountStart, LineProcessors::AccountStart),
        "90" => Handler.new(LineParsers::AccountEnd, LineProcessors::AccountEnd),
        "20" => Handler.new(LineParsers::PaymentStart, LineProcessors::PaymentStart),
        "25" => Handler.new(LineParsers::DeductionStart, LineProcessors::DeductionStart),
        "30" => Handler.new(LineParsers::ReferenceNumbers, LineProcessors::ReferenceNumbers),
        "40" => Handler.new(LineParsers::Messages, LineProcessors::Messages),
        "50" => Handler.new(LineParsers::Names, LineProcessors::Names.new(Document::Sender)),
        "51" => Handler.new(LineParsers::Addresses, LineProcessors::Addresses.new(Document::Sender)),
        "52" => Handler.new(LineParsers::Locality, LineProcessors::Locality.new(Document::Sender)),
        "60" => Handler.new(LineParsers::SenderAccount, LineProcessors::SenderAccount),
        "61" => Handler.new(LineParsers::Names, LineProcessors::Names.new(Document::SenderAccount)),
        "62" => Handler.new(LineParsers::Addresses, LineProcessors::Addresses.new(Document::SenderAccount)),
        "63" => Handler.new(LineParsers::Locality, LineProcessors::Locality.new(Document::SenderAccount)),
        "70" => Handler.new(LineParsers::International, LineProcessors::International)
      }
    end
  end
end
