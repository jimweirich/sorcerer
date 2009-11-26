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
      sexp.each do |s|
        if s.is_a?(Array)
          recur(s)
          if interesting?(s)
            @result << s
          end
        end
      end
    end

    def interesting?(sexp)
      sexp.is_a?(Array) &&
        (sexp.first == :var_ref ||
        sexp.first == :method_add_arg ||
        sexp.first == :regexp_literal ||
        sexp.first == :binary)
    end
  end
end
