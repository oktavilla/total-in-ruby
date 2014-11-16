module TotalIn
  module Typecaster
    def self.cast value, type
      casters.fetch(type).call(value) unless value == ""
    end

    def self.casters
      {
        integer: ->(value) { value.to_i },
        time: ->(value) { Time.parse(value) },
        date: ->(value) { Date.parse(value) },
        string: ->(value) { value }
      }
    end
  end
end
