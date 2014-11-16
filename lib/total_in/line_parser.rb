require "total_in/typecaster"

module TotalIn
  class LineParser
    attr_reader :line
    def initialize line
      @line = line
    end

    def self.field name, range, type = :string
      define_method name do
        if range.is_a?(Array)
          range.map { |r| value_at_position(r, type) }.compact
        else
          value_at_position range, type
        end
      end
    end

    private

    def value_at_position range, type
      typecast line[range].strip, type
    end

    def typecast value, type
      Typecaster.cast value, type
    end
  end
end
