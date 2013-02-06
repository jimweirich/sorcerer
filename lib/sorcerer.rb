module Sorcerer
  # Generate the source code for teh given Ripper S-Expression.
  def self.source(sexp, options={})
    Sorcerer::Resource.new(sexp, options).source
  end

  # Generate a list of interesting subexpressions for sexp.
  def self.subexpressions(sexp)
    Sorcerer::Subexpression.new(sexp).subexpressions
  end
end

require 'sorcerer/resource'
require 'sorcerer/signature'
require 'sorcerer/subexpression'
require 'sorcerer/version'
