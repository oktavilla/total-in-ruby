require "total_in/version"
require "total_in/parser"

module TotalIn
  def self.parse text
    Parser.new(text).result
  end
end
