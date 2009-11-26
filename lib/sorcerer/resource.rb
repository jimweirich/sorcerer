#!/usr/bin/env ruby

require 'ripper'

module Sorcerer 
  class Resource
    class NoHandlerError < StandardError
    end
    
    def initialize(sexp, debug=false)
      @sexp = sexp
      @source = ''
      @debug = debug
      @word_level = 0
    end
    
    def source
      resource(@sexp)
      @source
    end
    
    def resource(sexp)
      return unless sexp
      handler = Handlers[sexp.first]
      raise NoHandlerError.new(sexp.first) unless handler
      if @debug
        puts "----------------------------------------------------------"
        pp sexp
      end
      handler.call(self, sexp)
    end
    
    def handle_block(sexp)
      resource(sexp[1])     # Arguments
      if ! void?(sexp[2])
        emit(" ")
        resource(sexp[2])     # Statements
      end
      emit(" ")
    end
    
    def opt_parens(sexp)
      emit(" ") unless sexp.first == :arg_paren || sexp.first == :paren
      resource(sexp)
    end
    
    def emit(string)
      puts "EMITTING '#{string}'" if @debug
      @source << string
    end
    
    def nyi(sexp)
      raise "Handler for #{sexp.first} not implemented (#{sexp.inspect})"
    end
    
    def emit_separator(sep, first)
      emit(sep) unless first
      false
    end
    
    def params(normal_args, default_args, rest_args, unknown, block_arg)
      first = true
      if normal_args
        normal_args.each do |sx|
          first = emit_separator(", ", first)
          resource(sx)
        end
      end
      if default_args
        default_args.each do |sx|
          first = emit_separator(", ", first)
          resource(sx[0])
          emit("=")
          resource(sx[1])
        end
      end
      if rest_args
        first = emit_separator(", ", first)
        resource(rest_args)
      end
      if block_arg
        first = emit_separator(", ", first)
        resource(block_arg)
      end
    end
    
    def words(marker, sexp)
      emit("%#{marker}{") if @word_level == 0
      @word_level += 1
      if sexp[1] != [:qwords_new] && sexp[1] != [:words_new]
        resource(sexp[1])
        emit(" ")
      end
      resource(sexp[2])
      @word_level -= 1
      emit("}") if @word_level == 0
    end
    
    VOID_STATEMENT = [:stmts_add, [:stmts_new], [:void_stmt]]
    VOID_BODY = [:body_stmt, VOID_STATEMENT, nil, nil, nil]
    
    def void?(sexp)
      sexp.nil? ||
        sexp == VOID_STATEMENT ||
        sexp == VOID_BODY
    end
    
    NYI = lambda { |src, sexp| src.nyi(sexp) }
    DBG = lambda { |src, sexp| pp(sexp) }
    NOOP = lambda { |src, sexp| }
    SPACE = lambda { |src, sexp| src.emit(" ") }
    PASS1 = lambda { |src, sexp| src.resource(sexp[1]) }
    PASS2 = lambda { |src, sexp| src.resource(sexp[2]) }
    EMIT1 = lambda { |src, sexp| src.emit(sexp[1]) }
    
    Handlers = {
      # parser keywords
      
      :BEGIN => lambda { |src, sexp|
        src.emit("BEGIN {")
        unless src.void?(sexp[1])
          src.emit(" ")
          src.resource(sexp[1])
        end
        src.emit(" }")
      },
      :END => lambda { |src, sexp|
        src.emit("END {")
        unless src.void?(sexp[1])
          src.emit(" ")
          src.resource(sexp[1])
        end
        src.emit(" }")
      },
      :alias => lambda { |src, sexp|
        src.emit("alias ")
        src.resource(sexp[1])
        src.emit(" ")
        src.resource(sexp[2])
      },
      :alias_error => NYI,
      :aref => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit("[")
        src.resource(sexp[2])
        src.emit("]")
      },
      :aref_field => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit("[")
        src.resource(sexp[2])
        src.emit("]")
      },
      :arg_ambiguous => NYI,
      :arg_paren => lambda { |src, sexp|
        src.emit("(")
        src.resource(sexp[1]) if sexp[1]
        src.emit(")")
      },
      :args_add => lambda { |src, sexp|
        src.resource(sexp[1])
        if sexp[1].first != :args_new
          src.emit(", ")
        end
        src.resource(sexp[2])
      },
      :args_add_block => lambda { |src, sexp|
        src.resource(sexp[1])
        if sexp[2]
          if sexp[1].first != :args_new
            src.emit(", ")
          end
          if sexp[2]
            src.emit("&")
            src.resource(sexp[2])
          end
        end
      },
      :args_add_star => lambda { |src, sexp|
        src.resource(sexp[1])
        if sexp[1].first != :args_new
          src.emit(", ")
        end
        src.emit("*")
        src.resource(sexp[2])
      },
      :args_new => NOOP,
      :args_prepend => NYI,
      :array => lambda { |src, sexp|
        src.emit("[")
        src.resource(sexp[1])
        src.emit("]")
      },
      :assign => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(" = ")
        src.resource(sexp[2])
      },
      :assign_error => NYI,
      :assoc_new => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(" => ")
        src.resource(sexp[2])
      },
      :assoclist_from_args => lambda { |src, sexp|
        first = true
        sexp[1].each do |sx|
          src.emit(", ") unless first
          first = false
          src.resource(sx)
        end
      },
      :bare_assoc_hash => lambda { |src, sexp|
        first = true
        sexp[1].each do |sx|      
          src.emit(", ") unless first
          first = false
          src.resource(sx)
        end
      },
      :begin => lambda { |src, sexp|
        src.emit("begin")
        src.resource(sexp[1])
        src.emit("end")
      },
      :binary => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(" #{sexp[2]} ")
        src.resource(sexp[3])
      },
      :block_var => lambda { |src, sexp|
        src.emit(" |")
        src.resource(sexp[1])
        src.emit("|")
      },
      :block_var_add_block => NYI,
      :block_var_add_star => NYI,
      :blockarg => lambda { |src, sexp|
        src.emit("&")
        src.resource(sexp[1])
      },
      :body_stmt => lambda { |src, sexp|
        src.resource(sexp[1])     # Main Body
        src.emit("; ")
        src.resource(sexp[2])   # Rescue
        src.resource(sexp[4])   # Ensure
      },
      :brace_block => lambda { |src, sexp|
        src.emit(" {")
        src.handle_block(sexp)
        src.emit("}")
      },
      :break => lambda { |src, sexp|
        src.emit("break")
        src.emit(" ") unless sexp[1] == [:args_new]
        src.resource(sexp[1])
      },
      :call => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(sexp[2])
        src.resource(sexp[3]) unless sexp[3] == :call
      },
      :case => lambda { |src, sexp|
        src.emit("case ")
        src.resource(sexp[1])
        src.emit(" ")
        src.resource(sexp[2])
        src.emit(" end")
      },
      :class => lambda { |src, sexp|
        src.emit("class ")
        src.resource(sexp[1])
        if ! src.void?(sexp[2])
          src.emit " < "
          src.resource(sexp[2])
        end
        src.emit("; ")
        src.resource(sexp[3]) unless src.void?(sexp[3])
        src.emit("end")
      },
      :class_name_error => NYI,
      :command => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(" ")
        src.resource(sexp[2])
      },
      :command_call => NYI,
      :const_path_field => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit("::")
        src.resource(sexp[2])
      },
      :const_path_ref => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit("::")
        src.resource(sexp[2])
      },
      :const_ref => PASS1,
      :def => lambda { |src, sexp|
        src.emit("def ")
        src.resource(sexp[1])
        src.opt_parens(sexp[2])
        src.resource(sexp[3])
        src.emit("end")
      },
      :defined => lambda { |src, sexp|
        src.emit("defined?(")
        src.resource(sexp[1])
        src.emit(")")
      },
      :defs => NYI,
      :do_block => lambda { |src, sexp|
        src.emit(" do")
        src.handle_block(sexp)
        src.emit("end")
      },
      :dot2 => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit("..")
        src.resource(sexp[2])
      },
      :dot3 => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit("...")
        src.resource(sexp[2])
      },
      :dyna_symbol => lambda { |src, sexp|
        src.emit(':"')
        src.resource(sexp[1])
        src.emit('"')
      },
      :else => lambda { |src, sexp|
        src.emit(" else ")
        src.resource(sexp[1])
      },
      :elsif => lambda { |src, sexp|
        src.emit(" elsif ")
        src.resource(sexp[1])
        src.emit(" then ")
        src.resource(sexp[2])
        src.resource(sexp[3])
      },
      :ensure => lambda { |src, sexp|
        src.emit("ensure ")
        if sexp[1]
          src.resource(sexp[1])
          src.emit("; ") unless src.void?(sexp[1])
        end
      },
      :excessed_comma => NYI,
      :fcall => PASS1,
      :field => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(sexp[2])
        src.resource(sexp[3])
      },
      :for => lambda { |src, sexp|
        src.emit("for ")
        src.resource(sexp[1])
        src.emit(" in ")
        src.resource(sexp[2])
        src.emit(" do ")
        unless src.void?(sexp[3])
          src.resource(sexp[3])
          src.emit(" ")
        end
        src.emit("end")
      },
      :hash => lambda { |src, sexp|
        src.emit("{")
        src.resource(sexp[1])
        src.emit("}")
      },
      :if => lambda { |src, sexp|
        src.emit("if ")
        src.resource(sexp[1])
        src.emit(" then ")
        src.resource(sexp[2])
        src.resource(sexp[3])
        src.emit(" end")
      },
      :if_mod => lambda { |src, sexp|
        src.resource(sexp[2])
        src.emit(" if ")
        src.resource(sexp[1])
      },
      :ifop => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(" ? ")
        src.resource(sexp[2])
        src.emit(" : ")
        src.resource(sexp[3])
      },
      :lambda => lambda { |src, sexp|
        src.emit("->")
        src.resource(sexp[1])
        src.emit(" {")
        if ! src.void?(sexp[2])
          src.emit(" ")
          src.resource(sexp[2])
        end
        src.emit(" ")
        src.emit("}")
      },
      :magic_comment => NYI,
      :massign => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(" = ")
        src.resource(sexp[2])
      },
      :method_add_arg => lambda { |src, sexp|
        src.resource(sexp[1])
        src.resource(sexp[2])
      },
      :method_add_block => lambda { |src, sexp|
        src.resource(sexp[1])
        src.resource(sexp[2])
      },
      :mlhs_add => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(", ") unless sexp[1] == [:mlhs_new]
        src.resource(sexp[2])
      },
      :mlhs_add_star => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(", ") unless sexp[1] == [:mlhs_new]
        src.emit("*")
        src.resource(sexp[2])
      },
      :mlhs_new => NOOP,
      :mlhs_paren => lambda { |src, sexp|
        src.emit("(")
        src.resource(sexp[1])
        src.emit(")")
      },
      :module => lambda { |src, sexp|
        src.emit("module ")
        src.resource(sexp[1])
        if src.void?(sexp[2])
          src.emit("; ")
        else
          src.resource(sexp[2])
        end
        src.emit("end")
      },
      :mrhs_add => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(", ")
        src.resource(sexp[2])
      },
      :mrhs_add_star => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(", ")
        src.emit("*")
        src.resource(sexp[2])
      },
      :mrhs_new => NYI,
      :mrhs_new_from_args => PASS1,
      :next => lambda { |src, sexp|
        src.emit("next")
      },
      :opassign => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(" ")
        src.resource(sexp[2])
        src.emit(" ")
        src.resource(sexp[3])
      },
      :param_error => NYI,
      :params => lambda { |src, sexp|
        src.params(sexp[1], sexp[2], sexp[3], sexp[4], sexp[5])
      },
      :paren => lambda { |src, sexp|
        src.emit("(")
        src.resource(sexp[1])
        src.emit(")")
      },
      :parse_error => NYI,
      :program => PASS1,
      :qwords_add => lambda { |src, sexp|
        src.words("w", sexp)
      },
      :qwords_new => NOOP,
      :redo => lambda { |src, sexp|
        src.emit("redo")
      },
      :regexp_literal => lambda { |src, sexp|
        src.emit("/")
        src.resource(sexp[1])
        src.emit("/")
      },
      :rescue => lambda { |src, sexp|
        src.emit("rescue")
        if sexp[1]                # Exception list
          src.emit(" ")
          if sexp[1].first.kind_of?(Symbol)
            src.resource(sexp[1])
          else
            src.resource(sexp[1].first)
          end
          src.emit(" => ")
          src.resource(sexp[2]) 
        end
        src.emit(";")
        if sexp[3]                # Rescue Code
          if src.void?(sexp[3])
            src.emit(" ")
          else
            src.emit(" ")
            src.resource(sexp[3])
            src.emit("; ")
          end
        end
      },
      :rescue_mod => lambda { |src, sexp|
        src.resource(sexp[2])
        src.emit(" rescue ")
        src.resource(sexp[1])
      },
      :rest_param => lambda { |src, sexp|
        src.emit("*")
        src.resource(sexp[1])
      },
      :retry => lambda { |src, sexp|
        src.emit("retry")
      },
      :return => lambda { |src, sexp|
        src.emit("return")
        src.opt_parens(sexp[1])      
      },
      :return0 => lambda { |src, sexp|
        src.emit("return")
      },
      :sclass => NYI,
      :stmts_add => lambda { |src, sexp|
        if sexp[1] != [:stmts_new]
          src.resource(sexp[1])
          src.emit("; ")
        end
        src.resource(sexp[2])
      },
      :stmts_new => NOOP,
      :string_add => lambda { |src, sexp|
        src.resource(sexp[1])
        src.resource(sexp[2])
      },
      :string_concat => lambda { |src, sexp|
        src.resource(sexp[1])
        src.emit(" ")
        src.resource(sexp[2])
      },
      :string_content => NOOP,
      :string_dvar => NYI,
      :string_embexpr => lambda { |src, sexp|
        src.emit('#{')
        src.resource(sexp[1])
        src.emit('}')
      },
      :string_literal => lambda { |src, sexp|
        src.emit('"')
        src.resource(sexp[1])
        src.emit('"')
      },
      :super => lambda { |src, sexp|
        src.emit("super")
        src.opt_parens(sexp[1])
      },
      :symbol => lambda { |src, sexp|
        src.emit(":")
        src.resource(sexp[1])
      },
      :symbol_literal => PASS1,
      :top_const_field => NYI,
      :top_const_ref => NYI,
      :unary => lambda { |src, sexp|
        src.emit(sexp[1].to_s[0,1])
        src.resource(sexp[2])
      },
      :undef => lambda { |src, sexp|
        src.emit("undef ")
        src.resource(sexp[1].first)
      },
      :unless => lambda { |src, sexp|
        src.emit("unless ")
        src.resource(sexp[1])
        src.emit(" then ")
        src.resource(sexp[2])
        src.resource(sexp[3])
        src.emit(" end")
      },
      :unless_mod => lambda { |src, sexp|
        src.resource(sexp[2])
        src.emit(" unless ")
        src.resource(sexp[1])
      },
      :until => lambda { |src, sexp|
        src.emit("until ")
        src.resource(sexp[1])
        src.emit(" do ")
        src.resource(sexp[2])
        src.emit(" end")
      },
      :until_mod => lambda { |src, sexp|
        src.resource(sexp[2])
        src.emit(" until ")
        src.resource(sexp[1])
      },
      :var_alias => NYI,
      :var_field => PASS1,
      :var_ref => PASS1,
      :void_stmt => NOOP,
      :when => lambda { |src, sexp|
        src.emit("when ")
        src.resource(sexp[1])
        src.emit("; ")
        src.resource(sexp[2])
        if sexp[3] && sexp[3].first == :when
          src.emit(" ")
        end
        src.resource(sexp[3])      
      },
      :while => lambda { |src, sexp|
        src.emit("while ")
        src.resource(sexp[1])
        src.emit(" do ")
        src.resource(sexp[2])
        src.emit(" end")
      },
      :while_mod => lambda { |src, sexp|
        src.resource(sexp[2])
        src.emit(" while ")
        src.resource(sexp[1])
      },
      :word_add => PASS2,
      :word_new => NOOP,
      :words_add => lambda { |src, sexp|
        src.words("W", sexp)
      },
      :words_new => NOOP,
      :xstring_add => lambda { |src, sexp|
        src.resource(sexp[1])
        src.resource(sexp[2])
      },
      :xstring_literal => lambda { |src, sexp|
        src.emit('"')
        src.resource(sexp[1])
        src.emit('"')
      },
      :xstring_new => NOOP,
      :yield => lambda { |src, sexp|
        src.emit("yield")
        src.opt_parens(sexp[1])
      },
      :yield0 => lambda { |src, sexp|
        src.emit("yield")
      },
      :zsuper => lambda { |src, sexp|
        src.emit("super")
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
      :@label => NYI,
      :@lbrace => NYI,
      :@lbracket => NYI,
      :@lparen => NYI,
      :@nl => NYI,
      :@op => EMIT1,
      :@period => NYI,
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
  end
  
end
