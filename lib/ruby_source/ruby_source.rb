#!/usr/bin/env ruby

require 'ripper'

class RubySource
  class NoHandlerError < StandardError
  end

  def initialize(sexp, debug=false)
    @sexp = sexp
    @source = ''
    @debug = debug
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
    if sexp[2] != VOID_STATEMENT
      emit(" ")
      resource(sexp[2])     # Statements
    end
    emit(" ")
  end

  def emit(string)
    puts "EMITTING '#{string}'" if @debug
    @source << string
  end

  def nyi(sexp)
    raise "Handler for #{sexp.first} not implemented (#{sexp.inspect})"
  end

  VOID_STATEMENT = [:stmts_add, [:stmts_new], [:void_stmt]]

  NYI = lambda { |src, sexp| src.nyi(sexp) }
  DBG = lambda { |src, sexp| pp(sexp) }
  NOOP = lambda { |src, sexp| }
  SPACE = lambda { |src, sexp| src.emit(" ") }
  PASS1 = lambda { |src, sexp| src.resource(sexp[1]) }
  PASS2 = lambda { |src, sexp| src.resource(sexp[2]) }
  EMIT1 = lambda { |src, sexp| src.emit(sexp[1]) }

  Handlers = {
    # parser keywords

    :BEGIN => NYI,
    :END => NYI,
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
    :aref_field => NYI,
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
    :break => NYI,
    :call => lambda { |src, sexp|
      src.resource(sexp[1])
      src.emit(sexp[2])
      src.resource(sexp[3])
    },
    :case => lambda { |src, sexp|
      src.emit("case ")
      src.resource(sexp[1])
      src.emit(" ")
      src.resource(sexp[2])
      src.emit(" end")
    },
    :class => NYI,
    :class_name_error => NYI,
    :command => lambda { |src, sexp|
      src.resource(sexp[1])
      src.emit(" ")
      src.resource(sexp[2])
    },
    :command_call => NYI,
    :const_path_field => NYI,
    :const_path_ref => lambda { |src, sexp|
      src.resource(sexp[1])
      src.emit("::")
      src.resource(sexp[2])
    },
    :const_ref => NYI,
    :def => NYI,
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
        src.emit("; ") unless sexp[1] == VOID_STATEMENT
      end
    },
    :excessed_comma => NYI,
    :fcall => PASS1,
    :field => NYI,
    :for => NYI,
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
    :lambda => NYI,
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
    :module => NYI,
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
    :next => NYI,
    :opassign => lambda { |src, sexp|
      src.resource(sexp[1])
      src.emit(" ")
      src.resource(sexp[2])
      src.emit(" ")
      src.resource(sexp[3])
    },
    :param_error => NYI,
    :params => lambda { |src, sexp|
      first = true
      if sexp[1]
        sexp[1].each do |sx|
          src.emit(", ") unless first
          src.resource(sx)
          first = false
        end
      end
      if sexp[2]
        sexp[2].each do |sx|
          src.emit(", ") unless first
          first = false
          src.resource(sx[0])
          src.emit("=")
          src.resource(sx[1])
        end
      end
      if sexp[3]
        src.emit(", ") unless first
        first = false
        src.resource(sexp[3])
      end
      if sexp[5]
        src.emit(", ") unless first
        first = false
        src.resource(sexp[5])
      end
    },
    :paren => lambda { |src, sexp|
      src.emit("(")
      src.resource(sexp[1])
      src.emit(")")
    },
    :parse_error => NYI,
    :program => PASS1,
    :qwords_add => NYI,
    :qwords_new => NYI,
    :redo => NYI,
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
        if sexp[3] == VOID_STATEMENT
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
    :retry => NYI,
    :return => NYI,
    :return0 => NYI,
    :sclass => NYI,
    :stmts_add => lambda { |src, sexp|
      if sexp[1] != [:stmts_new]
        src.resource(sexp[1])
        src.emit("; ")
      end
      src.resource(sexp[2])
    },
    :stmts_new => NYI,
    :string_add => lambda { |src, sexp|
      src.resource(sexp[1])
      src.resource(sexp[2])
    },
    :string_concat => NYI,
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
    :super => NYI,
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
    :until => NYI,
    :until_mod => NYI,
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
    :word_add => NYI,
    :word_new => NYI,
    :words_add => NYI,
    :words_new => NYI,
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
    :yield => NYI,
    :yield0 => NYI,
    :zsuper => NYI,

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
    :@gvar => NYI,
    :@heredoc_beg => NYI,
    :@heredoc_end => NYI,
    :@ident => EMIT1,
    :@ignored_nl => NYI,
    :@int => EMIT1,
    :@ivar => EMIT1,
    :@kw => NYI,
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

