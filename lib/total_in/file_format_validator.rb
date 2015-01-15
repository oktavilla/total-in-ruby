require "total_in/line_parser"
module TotalIn
  class FileFormatValidator < LineParser
    field :record_type, 0..1, :raw
    field :file_type, 36..38

    def self.valid? line
      new(line).valid?
    end

    def valid?
      errors.empty?
    end

    def errors
      errors = []
      errors << "Must start with 00 (was ”#{record_type}”)" if record_type != "00"
      errors << "Must be of type TL1 (was ”#{file_type}”" if file_type != "TL1"

      errors
    end
  end
end
