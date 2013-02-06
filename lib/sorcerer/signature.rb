module Sorcerer
  class Signature

    attr_reader :normal_args, :default_args, :rest_arg, :keyword_args, :opts_arg, :block_arg

    def initialize(sexp)
      @normal_args = sexp[1]
      @default_args = sexp[2]
      @rest_arg = sexp[3]
      if ruby2_style_param_list?(sexp)
        @keyword_args = sexp[5]
        @opts_arg = sexp[6]
        @block_arg = sexp[7]
      else
        @block_arg = sexp[5]
      end
    end

    def empty?
      missing?(normal_args) &&
        missing?(default_args) &&
        missing?(rest_arg) &&
        missing?(keyword_args) &&
        missing?(opts_arg) &&
        missing?(block_arg)
    end

    private

    def missing?(args)
      args.nil? || args.empty?
    end

    def ruby2_style_param_list?(sexp)
      sexp.size == 8
    end
  end
end
