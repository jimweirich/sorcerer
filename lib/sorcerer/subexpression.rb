module Sorcerer
  class Subexpression
    def initialize(sexp)
      @sexp = sexp
    end

    def subexpressions
      sub_exp.map { |s| Sorcerer.source(s) }
    end

    def sub_exp
      @result = []
      recur(@sexp)
      @result
    end

    def recur(sexp)
      if sexp.is_a?(Array)
        if sexp.first.is_a?(Symbol)
          tagged_sexp(sexp)
        else
          list_sexp(sexp)
        end
      end
    end

    def list_sexp(sexp)
      sexp.each do |s|
        recur(s)
      end
    end

    def tagged_sexp(sexp)
      case sexp.first
      when :var_ref, :binary, :call, :array, :hash, :unary
        list_sexp(sexp)
        @result << sexp
      when :aref
        recur(sexp[2])
        @result << sexp
      when :method_add_arg
        list_sexp(sexp[2])
        recur(sexp[1][1])
        @result << sexp
      else
        list_sexp(sexp)
      end
    end
  end
end
