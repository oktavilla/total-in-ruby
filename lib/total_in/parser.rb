require "total_in/file_format_validator"
require "total_in/line_handlers"
require "total_in/contexts"

module TotalIn
  class InvalidFileFormatError < ArgumentError; end;

  class Parser
    attr_reader :text

    def initialize text
      validate_file_format text.each_line.peek
      @text = text
    end

    def result
      contexts = parse_lines text.each_line, Contexts.new

      contexts.result
    end

    private

    def validate_file_format line
      validator = FileFormatValidator.new line

      raise InvalidFileFormatError.new(validator.errors.join(", ")) unless validator.valid?
    end

    def parse_lines lines, contexts
      begin
        parse_lines lines, parse_line(lines.next, contexts)
      rescue StopIteration
        contexts
      end
    end

    def parse_line line, contexts
      handler = handler_for_line line

      handler.process line, contexts
    end

    def handler_for_line line
      LineHandlers.mapping.fetch line[0..1]
    end
  end
end
