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
        @result << sexp
        list_sexp(sexp)
      when :aref
        @result << sexp
        recur(sexp[2])
      when :method_add_arg
        @result << sexp
        recur(sexp[1][1])
        list_sexp(sexp[2])
      else
        list_sexp(sexp)
      end
    end
  end
end
