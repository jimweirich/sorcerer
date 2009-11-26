module Sorcerer
  # Generate the source code for teh given Ripper S-Expression.
  def Sorcerer.source(sexp, debug=false)
    Sorcerer::Resource.new(sexp, debug).source
  end
end

require 'sorcerer/resource'
require 'sorcerer/subexpression'

