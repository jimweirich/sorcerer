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
      when :var_ref
        list_sexp(sexp)
      when :vcall, :binary, :array, :hash, :unary, :defined
        @result << sexp
        list_sexp(sexp)
      when :aref
        @result << sexp
        recur(sexp[1])
        recur(sexp[2])
      when :brace_block
        # ignore
      when :call, :method_add_block, :method_add_arg
        @result << sexp
        method_sexp(sexp)
      when :const_path_ref
        @result << sexp
        recur(sexp[1])
      when :@kw
        # ignore
      when :@const
        @result << sexp
      when :zsuper, :super
        @result << sexp
        list_sexp(sexp)
      else
        list_sexp(sexp)
      end
    end

    def method_sexp(sexp)
      case sexp.first
      when :call
        recur(sexp[1])
      when :method_add_block
        method_sexp(sexp[1])
      when :method_add_arg
        recur(sexp[2])
        method_sexp(sexp[1])
      else
        recur(sexp)
      end
    end
  end
end
