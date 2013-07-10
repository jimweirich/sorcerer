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
      when :vcall               # [:vcall, target]
        @result << sexp
      when :fcall               # [:fcall, target]
        # ignore
      when :call                # [:call, target, ".", meth]
        @result << sexp
        recur(sexp[3])
        recur(sexp[1])
      when :method_add_arg      # [:method_add_arg, call, args]
        @result << sexp
        recur(sexp[2])
        within_method_sexp(sexp[1])
      when :method_add_block    # [:method_add_block, call, block]
        @result << sexp
        within_method_sexp(sexp[1])
      when :binary, :array, :hash, :unary, :defined
        @result << sexp
        list_sexp(sexp)
      when :aref
        @result << sexp
        recur(sexp[1])
        recur(sexp[2])
      when :brace_block         # [:brace_block, nil, statments]
        # ignore
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

    # When already handling a method call, we don't need to recur on
    # some items.
    def within_method_sexp(sexp)
      case sexp.first
      when :call                # [:call, target, ".", meth]
        recur(sexp[1])
      when :method_add_block    # [:method_add_block, call, block]
        within_method_sexp(sexp[1])
      when :method_add_arg      # [:method_add_arg, call, args]
        recur(sexp[2])
        within_method_sexp(sexp[1])
      else
        recur(sexp)
      end
    end
  end
end
