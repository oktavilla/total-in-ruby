require "total_in/file_format_validator"
require "total_in/line_handlers"
require "total_in/contexts"

module TotalIn
  class InvalidFileFormatError < ArgumentError; end;

  class Parser
    attr_reader :file

    # Parser.new accepts a File instance or a String
    # A InvalidFileFormatError will be raised if file isn't in the TotalIn format
    def initialize file
      @file = file
      validate_file_format
    end

    def result
      contexts = self.lines.each_with_object(Contexts.new) do |line, c|
        parse_line line, c
      end

      contexts.result
    end

    protected

    def lines
      file.each_line
    end

    private

    def validate_file_format
      unless FileFormatValidator.new(first_line).valid?
        raise InvalidFileFormatError.new validator.errors.join(", ")
      end
    end

    # Look up a matching handler for the line and process it
    # The process method on a handler always returns a Contexts object
    def parse_line line, contexts
      line = line.encode Encoding::UTF_8 if encode_lines?

      handler = handler_for_line line

      handler.process line, contexts
    end

    def handler_for_line line
      LineHandlers.mapping.fetch line[0..1]
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
