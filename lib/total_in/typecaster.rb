require "time"

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
        string: ->(value) { value unless value.match(/\A0+\Z/) }
      }
    end
  end
end
