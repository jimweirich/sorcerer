#!/usr/bin/env ruby

require 'ripper'

module Sorcerer
  class Resource
    class SorcererError < StandardError
    end

    class NoHandlerError < SorcererError
    end

    class NotSexpError < SorcererError
    end

    class UnexpectedSexpError < SorcererError
    end

    def initialize(sexp, options={})
      @sexp = sexp
      @debug = options[:debug]
      @indent = options[:indent] || 0
      @indent = 2 if @indent && ! @indent.is_a?(Integer)
      @multiline = options[:multiline] || indenting?

      @source = ''
      @word_level = 0
      @stack = []
      @level = 0
      @virgin_line = true
    end

    def source
      @stack.clear
      resource(@sexp)
      if multiline?
        @source << "\n" unless @source =~ /\n\z/m
      end
      @source
    end

    private

    def multiline?
      @multiline
    end

    def indenting?
      @indent > 0
    end

    def indent
      old_level = @level
      @level += 1
      yield
    ensure
      @level = old_level
    end

    def outdent
      old_level = @level
      @level -= 1
      yield
    ensure
      @level = old_level
    end

    def sexp?(obj)
      obj && obj.respond_to?(:each) && obj.first.is_a?(Symbol)
    end

    def nested_sexp?(obj)
      obj && obj.respond_to?(:first) && sexp?(obj.first)
    end

    def resource(sexp)
      fail NotSexpError, "Not an S-EXPER: #{sexp.inspect}" unless sexp?(sexp)
      handler = HANDLERS[sexp.first]
      raise NoHandlerError.new(sexp.first) unless handler
      if @debug
        puts "----------------------------------------------------------"
        pp sexp
      end
      apply_handler(sexp, handler)
    end

    def apply_handler(sexp, handler)
      @stack.push(sexp.first)
      instance_exec(sexp, &handler)
    ensure
      @stack.pop
    end

    def emit_block(sexp, do_word, end_word)
      emit(" ")
      emit(do_word)
      resource(sexp[1]) if sexp[1] # Arguments
      indent do
        if ! void?(sexp[2])
          soft_newline
          resource(sexp[2])     # Statements
        end
        if !void?(sexp[2])
          soft_newline
        else
          emit(" ")
        end
      end
      emit(end_word)
    end

    def params_have_parens?(sexp)
      sexp.first == :arg_paren || sexp.first == :paren
    end

    def params_are_empty?(sexp)
      params = sexp
      params = sexp[1] if sexp.first == :paren || sexp.first == :arg_paren
      sig = Signature.new(params)
      sig.empty?
    end

    def opt_parens(sexp)
      if !params_have_parens?(sexp) && ! params_are_empty?(sexp)
        emit(" ")
      end
      resource(sexp)
    end

    def emit(string)
      emit_raw("  " * @level) if indenting? && virgin_line?
      @virgin_line = false
      emit_raw(string.to_s)
    end

    def emit_raw(string)
      puts "EMITTING '#{string}' (#{last_handler}) [#{@level}]" if @debug
      @source << string.to_s
    end

    def nyi(sexp)
      raise "Handler for #{sexp.first} not implemented (#{sexp.inspect})"
    end

    def emit_then
      if multiline?
        soft_newline
      else
        emit(" then ")
      end
    end

    def emit_separator(sep, first)
      emit(sep) unless first
      false
    end

    def params(sig)
      first = true
      if sig.normal_args
        sig.normal_args.each do |sx|
          first = emit_separator(", ", first)
          resource(sx)
        end
      end
      if sig.default_args
        sig.default_args.each do |sx|
          first = emit_separator(", ", first)
          resource(sx[0])
          emit("=")
          resource(sx[1])
        end
      end
      if sig.rest_arg
        first = emit_separator(", ", first)
        resource(sig.rest_arg)
      end
      if sig.keyword_args
        sig.keyword_args.each do |sx|
          first = emit_separator(", ", first)
          resource(sx[0])
          emit(" ")
          resource(sx[1])
        end
      end
      if sig.opts_arg
        first = emit_separator(", ", first)
        emit("**")
        emit(sig.opts_arg[1])
      end
      if sig.block_arg
        first = emit_separator(", ", first)
        resource(sig.block_arg)
      end
    end

    def quoted_word_add?(sexp)
      sexp &&
        sexp[1] &&
        [:words_add, :qwords_add, :qsymbols_add, :symbols_add].include?(sexp[1].first)
    end

    def quoted_word_new?(sexp)
      sexp &&
        sexp[1] &&
        [:qwords_new, :words_new, :qsymbols_new, :symbols_new].include?(sexp[1].first)
    end

    def words(marker, sexp)
      emit("%#{marker}{") if @word_level == 0
      @word_level += 1
      if !quoted_word_new?(sexp)
        resource(sexp[1])
        emit(" ")
      end
      resource(sexp[2])
      @word_level -= 1
      emit("}") if @word_level == 0
    end

    VOID_STATEMENT = [:stmts_add, [:stmts_new], [:void_stmt]]
    VOID_STATEMENT2 = [:stmts_add, [:stmts_new]]
    VOID_BODY = [:body_stmt, VOID_STATEMENT, nil, nil, nil]
    VOID_BODY2 = [:bodystmt, VOID_STATEMENT, nil, nil, nil]

    def void?(sexp)
      sexp.nil? ||
        sexp == VOID_STATEMENT ||
        sexp == VOID_STATEMENT2 ||
        sexp == VOID_BODY ||
        sexp == VOID_BODY2
    end

    def label?(sexp)
      sexp?(sexp) && sexp.first == :@label
    end

    def last_handler
      @stack.last
    end

    def virgin_line?
      @virgin_line
    end

    def newline
      if multiline?
        emit("\n")
        @virgin_line = true
      else
        emit("; ")
      end
    end

    def soft_newline
      if multiline?
        newline
      else
        emit(" ")
      end
    end

    BALANCED_DELIMS = {
      '}' => '{',
      ')' => '(',
      '>' => '<',
      ']' => '[',
    }

    def determine_regexp_delimiters(sexp)
      sym, end_delim, _ = sexp
      fail UnexpectedSexpError, "Expected :@regexp_end, got #{sym.inspect}" unless sym == :@regexp_end
      end_delim_char = end_delim[0]
      first_delim = BALANCED_DELIMS[end_delim_char] || end_delim_char
      if first_delim != '/'
        first_delim = "%r#{first_delim}"
      end
      [first_delim, end_delim]
    end

    NYI = lambda { |sexp| nyi(sexp) }
    DBG = lambda { |sexp| pp(sexp) }
    NOOP = lambda { |sexp| }
    SPACE = lambda { |sexp| emit(" ") }
    PASS1 = lambda { |sexp| resource(sexp[1]) }
    PASS2 = lambda { |sexp| resource(sexp[2]) }
    PASSBOTH = lambda { |sexp| resource(sexp[1]); resource(sexp[2]) }
    EMIT1 = lambda { |sexp| emit(sexp[1]) }

    # Earlier versions of ripper miss array node for words, see
    # http://bugs.ruby-lang.org/issues/4365 for more details
    MISSES_ARRAY_NODE_FOR_WORDS = RUBY_VERSION < '1.9.2' ||
      (RUBY_VERSION == '1.9.2' && RUBY_PATCHLEVEL < 320)

    HANDLERS = {
      # parser keywords

      :BEGIN => lambda { |sexp|
        emit("BEGIN {")
        if void?(sexp[1])
          emit " }"
        else
          soft_newline
          indent do
            resource(sexp[1])
            soft_newline
          end
          emit("}")
        end
      },
      :END => lambda { |sexp|
        emit("END {")
        if void?(sexp[1])
          emit(" }")
        else
          soft_newline
          indent do
            resource(sexp[1])
            soft_newline
          end
          emit("}")
        end
      },
      :alias => lambda { |sexp|
        emit("alias ")
        resource(sexp[1])
        emit(" ")
        resource(sexp[2])
      },
      :alias_error => NYI,
      :aref => lambda { |sexp|
        resource(sexp[1])
        emit("[")
        resource(sexp[2])
        emit("]")
      },
      :aref_field => lambda { |sexp|
        resource(sexp[1])
        emit("[")
        resource(sexp[2])
        emit("]")
      },
      :arg_ambiguous => NYI,
      :arg_paren => lambda { |sexp|
        emit("(")
        resource(sexp[1]) if sexp[1]
        emit(")")
      },
      :args_add => lambda { |sexp|
        resource(sexp[1])
        if sexp[1].first != :args_new
          emit(", ")
        end
        resource(sexp[2])
      },
      :args_add_block => lambda { |sexp|
        resource(sexp[1])
        if sexp[2]
          if sexp[1].first != :args_new
            emit(", ")
          end
          if sexp[2]
            emit("&")
            resource(sexp[2])
          end
        end
      },
      :args_add_star => lambda { |sexp|
        resource(sexp[1])
        if sexp[1].first != :args_new
          emit(", ")
        end
        emit("*")
        resource(sexp[2])
      },
      :args_new => NOOP,
      :args_prepend => NYI,
      :array => lambda { |sexp|
        if !MISSES_ARRAY_NODE_FOR_WORDS &&
            quoted_word_add?(sexp)
          resource(sexp[1])
        else
          emit("[")
          resource(sexp[1]) if sexp[1]
          emit("]")
        end
      },
      :assign => lambda { |sexp|
        resource(sexp[1])
        emit(" = ")
        resource(sexp[2])
      },
      :assign_error => NYI,
      :assoc_new => lambda { |sexp|
        resource(sexp[1])
        if label?(sexp[1])
          emit(" ")
        else
          emit(" => ")
        end
        resource(sexp[2])
      },
      :assoclist_from_args => lambda { |sexp|
        first = true
        sexp[1].each do |sx|
          emit(", ") unless first
          first = false
          resource(sx)
        end
      },
      :bare_assoc_hash => lambda { |sexp|
        first = true
        sexp[1].each do |sx|
          emit(", ") unless first
          first = false
          resource(sx)
        end
      },
      :begin => lambda { |sexp|
        emit("begin")
        indent do
          if void?(sexp[1])
            emit(" ")
          else
            soft_newline
            resource(sexp[1])
          end
        end
        emit("end")
      },
      :binary => lambda { |sexp|
        resource(sexp[1])
        emit(" #{sexp[2]} ")
        resource(sexp[3])
      },
      :block_var => lambda { |sexp|
        emit(" |")
        resource(sexp[1])
        emit("|")
      },
      :block_var_add_block => NYI,
      :block_var_add_star => NYI,
      :blockarg => lambda { |sexp|
        emit("&")
        resource(sexp[1])
      },
      :body_stmt => lambda { |sexp|
        resource(sexp[1])     # Main Body
        newline unless void?(sexp[1])
        resource(sexp[2]) if sexp[2]  # Rescue
        resource(sexp[4]) if sexp[4]  # Ensure
      },
      :brace_block => lambda { |sexp|
        emit_block(sexp, "{", "}")
      },
      :break => lambda { |sexp|
        emit("break")
        emit(" ") unless sexp[1] == [:args_new]
        resource(sexp[1])
      },
      :call => lambda { |sexp|
        resource(sexp[1])
        emit(sexp[2])
        resource(sexp[3]) unless sexp[3] == :call
      },
      :case => lambda { |sexp|
        emit("case ")
        resource(sexp[1])
        soft_newline
        indent do
          resource(sexp[2])
          newline
        end
        emit("end")
      },
      :class => lambda { |sexp|
        emit("class ")
        resource(sexp[1])
        if ! void?(sexp[2])
          emit " < "
          resource(sexp[2])
        end
        newline
        indent do
          resource(sexp[3]) unless void?(sexp[3])
        end
        emit("end")
      },
      :class_name_error => NYI,
      :command => lambda { |sexp|
        resource(sexp[1])
        emit(" ")
        resource(sexp[2])
      },
      :command_call => lambda { |sexp|
        resource(sexp[1])
        emit(sexp[2])
        resource(sexp[3])
        emit(" ")
        resource(sexp[4])
      },
      :const_path_field => lambda { |sexp|
        resource(sexp[1])
        emit("::")
        resource(sexp[2])
      },
      :const_path_ref => lambda { |sexp|
        resource(sexp[1])
        emit("::")
        resource(sexp[2])
      },
      :const_ref => PASS1,
      :def => lambda { |sexp|
        emit("def ")
        resource(sexp[1])
        opt_parens(sexp[2])
        newline
        indent do resource(sexp[3]) end
        emit("end")
      },
      :defined => lambda { |sexp|
        emit("defined?(")
        resource(sexp[1])
        emit(")")
      },
      :defs => lambda { |sexp|
        emit("def ")
        resource(sexp[1])
        resource(sexp[2])
        resource(sexp[3])
        opt_parens(sexp[4])
        newline
        indent do resource(sexp[5]) end
        emit("end")
      },
      :do_block => lambda { |sexp|
        emit_block(sexp, "do", "end")
      },
      :dot2 => lambda { |sexp|
        resource(sexp[1])
        emit("..")
        resource(sexp[2])
      },
      :dot3 => lambda { |sexp|
        resource(sexp[1])
        emit("...")
        resource(sexp[2])
      },
      :dyna_symbol => lambda { |sexp|
        emit(':"')
        resource(sexp[1])
        emit('"')
      },
      :else => lambda { |sexp|
        soft_newline
        outdent do emit("else") end
        soft_newline
        resource(sexp[1])
      },
      :elsif => lambda { |sexp|
        soft_newline
        outdent do emit("elsif ") end
        resource(sexp[1])
        emit_then
        resource(sexp[2])
        resource(sexp[3]) if sexp[3]
      },
      :ensure => lambda { |sexp|
        outdent do emit("ensure") end
        if void?(sexp[1])
          soft_newline
        else
          soft_newline
          resource(sexp[1])
          newline unless void?(sexp[1])
        end
      },
      :excessed_comma => NYI,
      :fcall => PASS1,
      :field => lambda { |sexp|
        resource(sexp[1])
        emit(sexp[2])
        resource(sexp[3])
      },
      :for => lambda { |sexp|
        emit("for ")
        resource(sexp[1])
        emit(" in ")
        resource(sexp[2])
        newline
        indent do
          unless void?(sexp[3])
            resource(sexp[3])
            soft_newline
          end
        end
        emit("end")
      },
      :hash => lambda { |sexp|
        emit("{")
        if sexp[1]
          emit(" ")
          resource(sexp[1])
        end
        emit(" }")
      },
      :if => lambda { |sexp|
        emit("if ")
        resource(sexp[1])
        emit_then
        indent do
          resource(sexp[2])
          resource(sexp[3]) if sexp[3]
          soft_newline
        end
        emit("end")
      },
      :if_mod => lambda { |sexp|
        resource(sexp[2])
        emit(" if ")
        resource(sexp[1])
      },
      :ifop => lambda { |sexp|
        resource(sexp[1])
        emit(" ? ")
        resource(sexp[2])
        emit(" : ")
        resource(sexp[3])
      },
      :lambda => lambda { |sexp|
        emit("->")
        resource(sexp[1])
        emit(" {")
        indent do
          if ! void?(sexp[2])
            soft_newline
            resource(sexp[2])
          end
          if void?(sexp[2])
            emit(" ")
          else
            soft_newline
          end
        end
        emit("}")
      },
      :magic_comment => NYI,
      :massign => lambda { |sexp|
        resource(sexp[1])
        emit(" = ")
        resource(sexp[2])
      },
      :method_add_arg => PASSBOTH,
      :method_add_block => PASSBOTH,
      :mlhs_add => lambda { |sexp|
        resource(sexp[1])
        emit(", ") unless sexp[1] == [:mlhs_new]
        resource(sexp[2])
      },
      :mlhs_add_star => lambda { |sexp|
        resource(sexp[1])
        emit(", ") unless sexp[1] == [:mlhs_new]
        emit("*")
        resource(sexp[2])
      },
      :mlhs_new => NOOP,
      :mlhs_paren => lambda { |sexp|
        emit("(")
        resource(sexp[1])
        emit(")")
      },
      :module => lambda { |sexp|
        emit("module ")
        resource(sexp[1])
        newline
        unless void?(sexp[2])
          indent do resource(sexp[2]) end
        end
        emit("end")
      },
      :mrhs_add => lambda { |sexp|
        resource(sexp[1])
        emit(", ")
        resource(sexp[2])
      },
      :mrhs_add_star => lambda { |sexp|
        resource(sexp[1])
        emit(", ") unless sexp[1] == [:mrhs_new]
        emit("*")
        resource(sexp[2])
      },
      :mrhs_new => NOOP,
      :mrhs_new_from_args => PASS1,
      :next => lambda { |sexp|
        emit("next")
      },
      :opassign => lambda { |sexp|
        resource(sexp[1])
        emit(" ")
        resource(sexp[2])
        emit(" ")
        resource(sexp[3])
      },
      :param_error => NYI,
      :params => lambda { |sexp|
        params(Signature.new(sexp))
      },
      :paren => lambda { |sexp|
        emit("(")
        resource(sexp[1])
        emit(")")
      },
      :parse_error => NYI,
      :program => PASS1,
      :qsymbols_add => lambda { |sexp|
        words("i", sexp)
      },
      :qsymbols_new => NOOP,
      :qwords_add => lambda { |sexp|
        words("w", sexp)
      },
      :qwords_new => NOOP,
      :redo => lambda { |sexp|
        emit("redo")
      },
      :regexp_add => PASSBOTH,
      :regexp_literal => lambda { |sexp|
        delims = determine_regexp_delimiters(sexp[2])
        emit(delims[0])
        resource(sexp[1])
        emit(delims[1])
      },
      :regexp_new => NOOP,
      :rescue => lambda { |sexp|
        outdent do emit("rescue") end
        if sexp[1]                # Exception list
          emit(" ")
          if sexp[1].first.kind_of?(Symbol)
            resource(sexp[1])
          else
            resource(sexp[1].first)
          end
        end
        if sexp[2]
          emit(" => ")
          resource(sexp[2])
        end
        newline
        if sexp[3] && ! void?(sexp[3])
          resource(sexp[3])
          newline
        end
      },
      :rescue_mod => lambda { |sexp|
        if RUBY_VERSION <= '1.9.2'
          # Pre ruby 1.9.3 these nodes were returned in the reverse order, see
          # http://bugs.ruby-lang.org/issues/4716 for more details
          first_node, second_node = sexp[2], sexp[1]
        else
          first_node, second_node = sexp[1], sexp[2]
        end
        resource(first_node)
        emit(" rescue ")
        resource(second_node)
      },
      :rest_param => lambda { |sexp|
        emit("*")
        resource(sexp[1])
      },
      :retry => lambda { |sexp|
        emit("retry")
      },
      :return => lambda { |sexp|
        emit("return")
        opt_parens(sexp[1])
      },
      :return0 => lambda { |sexp|
        emit("return")
      },
      :sclass => NYI,
      :stmts_add => lambda { |sexp|
        if sexp[1] != [:stmts_new] && ! void?(sexp[1])
          resource(sexp[1])
          newline
        end
        resource(sexp[2]) if sexp[2]
      },
      :stmts_new => NOOP,
      :string_add => PASSBOTH,
      :string_concat => lambda { |sexp|
        resource(sexp[1])
        emit(" ")
        resource(sexp[2])
      },
      :string_content => NOOP,
      :string_dvar => NYI,
      :string_embexpr => lambda { |sexp|
        emit('#{')
        resource(sexp[1])
        emit('}')
      },
      :string_literal => lambda { |sexp|
        emit('"')
        resource(sexp[1])
        emit('"')
      },
      :super => lambda { |sexp|
        emit("super")
        opt_parens(sexp[1])
      },
      :symbol => lambda { |sexp|
        emit(":")
        resource(sexp[1])
      },
      :symbol_literal => PASS1,
      :symbols_add => lambda { |sexp|
        words("I", sexp)
      },
      :symbols_new => NOOP,
      :top_const_field => NYI,
      :top_const_ref => NYI,
      :unary => lambda { |sexp|
        op = sexp[1].to_s
        op = op[0,1] if op =~ /^.@$/
        emit(op)
        emit(" ") if op.size > 1
        resource(sexp[2])
      },
      :undef => lambda { |sexp|
        emit("undef ")
        resource(sexp[1].first)
      },
      :unless => lambda { |sexp|
        emit("unless ")
        resource(sexp[1])
        emit_then
        indent do
          resource(sexp[2])
          resource(sexp[3]) if sexp[3]
          soft_newline
        end
        emit("end")
      },
      :unless_mod => lambda { |sexp|
        resource(sexp[2])
        emit(" unless ")
        resource(sexp[1])
      },
      :until => lambda { |sexp|
        emit("until ")
        resource(sexp[1])
        newline
        indent do resource(sexp[2]) end
        emit(" end")
      },
      :until_mod => lambda { |sexp|
        resource(sexp[2])
        emit(" until ")
        resource(sexp[1])
      },
      :var_alias => NYI,
      :var_field => PASS1,
      :var_ref => PASS1,
      :vcall => PASS1,
      :void_stmt => NOOP,
      :when => lambda { |sexp|
        outdent do emit("when ") end
        resource(sexp[1])
        newline
        resource(sexp[2])
        if sexp[3] && sexp[3].first == :when
          emit(" ")
        end
        resource(sexp[3]) if sexp[3]
      },
      :while => lambda { |sexp|
        emit("while ")
        resource(sexp[1])
        newline
        indent do
          unless void?(sexp[2])
            resource(sexp[2])
            newline
          end
        end
        emit("end")
      },
      :while_mod => lambda { |sexp|
        resource(sexp[2])
        emit(" while ")
        resource(sexp[1])
      },
      :word_add => PASS2,
      :word_new => NOOP,
      :words_add => lambda { |sexp|
        words("W", sexp)
      },
      :words_new => NOOP,
      :xstring_add => PASSBOTH,
      :xstring_literal => lambda { |sexp|
        emit('"')
        resource(sexp[1])
        emit('"')
      },
      :xstring_new => NOOP,
      :yield => lambda { |sexp|
        emit("yield")
        opt_parens(sexp[1])
      },
      :yield0 => lambda { |sexp|
        emit("yield")
      },
      :zsuper => lambda { |sexp|
        emit("super")
      },

      # Scanner keywords

      :@CHAR => NYI,
      :@__end__ => NYI,
      :@backref => NYI,
      :@backtick => NYI,
      :@comma => NYI,
      :@comment => NYI,
      :@const => EMIT1,
      :@cvar => EMIT1,
      :@embdoc => NYI,
      :@embdoc_beg => NYI,
      :@embdoc_end => NYI,
      :@embexpr_beg => NYI,
      :@embexpr_end => NYI,
      :@embvar => NYI,
      :@float => EMIT1,
      :@gvar => EMIT1,
      :@heredoc_beg => NYI,
      :@heredoc_end => NYI,
      :@ident => EMIT1,
      :@ignored_nl => NYI,
      :@int => EMIT1,
      :@ivar => EMIT1,
      :@kw => EMIT1,
      :@label => EMIT1,
      :@lbrace => NYI,
      :@lbracket => NYI,
      :@lparen => NYI,
      :@nl => NYI,
      :@op => EMIT1,
      :@period => EMIT1,
      :@qwords_beg => NYI,
      :@rbrace => NYI,
      :@rbracket => NYI,
      :@regexp_beg => NYI,
      :@regexp_end => NYI,
      :@rparen => NYI,
      :@semicolon => NYI,
      :@sp => NYI,
      :@symbeg  => NYI,
      :@tlambda => NYI,
      :@tlambeg => NYI,
      :@tstring_beg => NYI,
      :@tstring_content => EMIT1,
      :@tstring_end => NYI,
      :@words_beg => NYI,
      :@words_sep => NYI,
    }
    HANDLERS[:bodystmt] = HANDLERS[:body_stmt]
  end

end
