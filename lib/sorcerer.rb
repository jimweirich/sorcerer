module Sorcerer
  # Generate the source code for teh given Ripper S-Expression.
  def self.source(sexp, debug=false)
    Sorcerer::Resource.new(sexp, debug).source
  end

  # Generate a list of interesting subexpressions for sexp.
  def self.subexpressions(sexp)
    Sorcerer::Subexpression.new(sexp)
  end
end

require 'sorcerer/resource'
require 'sorcerer/subexpression'

