#!/usr/bin/env ruby

require 'test/unit'
require 'ripper'
require 'sorcerer'
require 'assert_resource_helper'

class ResourceTest < Test::Unit::TestCase
  include AssertResource

  private

  def quietly
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = original_verbosity
  end

  def source(string, options={})
    if options[:debug]
      puts
      puts "***************************** options: #{options.inspect}"
    end
    sexp = quietly {
      if options[:quick]
        Ripper.sexp(string)
      else
        Ripper::SexpBuilder.new(string).parse
      end
    }
    fail "Failed to parts '#{string}'" if sexp.nil?
    Sorcerer.source(sexp, options)
  end

  public

  def test_can_source_variables
    assert_resource "a"
    assert_resource "b"
  end

  def test_can_source_constants
    assert_resource "A"
    assert_resource "Mod::X"
    assert_resource "Mod::NS::Y"
  end

  def test_can_source_keywords
    assert_resource "true"
    assert_resource "false"
    assert_resource "nil"
  end

  def test_can_source_constant_definition
    assert_resource "X = 1"
    assert_resource "X::Y = 1"
    assert_resource "X::Y::Z = 1"
  end

  def test_can_source_instance_variables
    assert_resource "@iv"
  end

  def test_can_source_class_instance_variables
   assert_resource "@@iv"
  end

  def test_can_source_globals
   assert_resource "$g"
  end

  def test_can_source_method_call_without_args
    assert_resource "obj.meth"
    assert_resource "obj.meth()"
  end

  def test_can_source_method_call_with_args
    assert_resource "obj.meth(a)"
    assert_resource "obj.meth(a, b)"
    assert_resource "obj.meth(a, b, c)"
  end

  def test_can_source_method_call_with_star_args
    assert_resource "obj.meth(*args)"
    assert_resource "obj.meth(a, *args)"
  end

  def test_can_source_method_call_with_block_args
    assert_resource "obj.meth(&code)"
    assert_resource "obj.meth(a, &code)"
    assert_resource "obj.meth(a, *args, &code)"
  end

  def test_can_source_method_call_without_parens
    assert_resource "obj.meth a"
    assert_resource "obj.meth a, b"
    assert_resource "obj.meth a, b, c"
    assert_resource "obj.meth *args"
    assert_resource "obj.meth a, *args"
    assert_resource "obj.meth &code"
    assert_resource "obj.meth a, &code"
    assert_resource "obj.meth a, *args, &code"
    assert_resource "obj.meth a, *args do |x| x.y end"
  end

  def test_can_source_method_called_with_scope_op_without_parans
    assert_resource "Const::meth"
    assert_resource "Const::meth a"
    assert_resource "Const::meth a, b"
    assert_resource "Const::meth a, *b"
    assert_resource "Const::meth a, *b, &block"
  end

  def xtest_can_source_method_called_with_scope_op_with_parens
    # I don't think we get enough info to accurately resource these.
    # All these calls come back with a period rather than a double
    # colon.
    skip "Can't resource methods calls with ::"
    assert_resource "Const::meth(a)"
    assert_resource "Const::meth(a, b)"
    assert_resource "Const::meth(a, *b)"
    assert_resource "Const::meth(a, *b, &block)"
  end

  def test_can_source_method_without_explicit_target
    assert_resource "meth(a)"
    assert_resource "meth(a, b)"
    assert_resource "meth(a, b, c)"
    assert_resource "meth(*args)"
    assert_resource "meth(a, *args)"
    assert_resource "meth(&code)"
    assert_resource "meth(a, &code)"
    assert_resource "meth(a, *args, &code)"
  end

  def test_can_source_capitalized_method_without_explicit_target
    assert_resource "Meth()"
    assert_resource "Meth a"
    assert_resource "Meth(a)"
    assert_resource "Meth { a }"
  end

  def test_can_source_method_without_explicit_target_in_poetry_mode
    assert_resource "meth a"
    assert_resource "meth a, b"
    assert_resource "meth a, b, c"
    assert_resource "meth *args"
    assert_resource "meth a, *args"
    assert_resource "meth &code"
    assert_resource "meth a, &code"
    assert_resource "meth a, *args, &code"
    assert_resource "meth a, *args do |x| x.y end"
  end

  def test_can_source_method_with_bare_assoc
    assert_resource "meth(:x => 1)"
    assert_resource "meth(:x => 1, :y => 2)"
    assert_resource "meth(a, :x => 1)"
    assert_resource "meth(a, :x => 1, :y => 2)"
  end

  def test_can_source_method_with_new_hash_syntax
    assert_resource "meth(x: 1)"
    assert_resource "meth(x: 1, y: 2)"
    assert_resource "meth(a, x: 1)"
    assert_resource "meth(a, x: 1, y: 2)"
    assert_resource "meth(a, :x => 1, y: 2)"
  end

  def test_can_source_method_with_do_block
    assert_resource_lines "meth do end"
    assert_resource_lines "meth do |a| end"
    assert_resource_lines "meth(x, y, *rest, &code) do |a, b=1, c=x, *args, &block|~#one; #two; #three~end"
  end

  def test_can_source_method_with_block
    assert_resource_lines "meth { }"
    assert_resource_lines "meth { |a| }"
    assert_resource_lines "meth { |a, b| }"
    assert_resource_lines "meth { |*args| }"
    assert_resource_lines "meth { |a, *args| }"
    assert_resource_lines "meth { |&block| }"
    assert_resource_lines "meth { |*args, &block| }"
    assert_resource_lines "meth { |a, b, *args, &block| }"
    assert_resource_lines "meth { |a, b=1, *args, &block| }"
    assert_resource_lines "meth { |a, b=1, c=x, *args, &block| }"
  end

  def test_can_source_method_with_block_contents
    assert_resource_lines "meth { |a|~#a.x~}"
    assert_resource_lines "meth { |a|~#a.x; #b.z~}"
  end

  def test_can_source_method_with_complex_args_and_block
    assert_resource_lines "meth(x, y, *rest, &code) { |a, b=1, c=x, *args, &block|~#one; #two; #three~}"
  end

  def test_can_source_stabby_procs
    assert_resource_lines "-> { }"
    assert_resource_lines "->() { }"
    assert_resource_lines "->(a) { }"
    assert_resource_lines "->(a, b) { }"
    assert_resource_lines "->(a, *args) { }"
    assert_resource_lines "->(a, b=12, *args, &block) { }"
    assert_resource_lines "->(a) {~#b~}"
  end

  def test_can_source_dot_calls
    if RUBY_VERSION >= "1.9.2"
      # This causes a bus fault on version 1.9.1
      assert_resource "p.(a)"
    end
  end

  def test_can_source_numbers
    assert_resource "1"
    assert_resource "3.14"
  end

  def test_can_source_strings
    assert_resource '"HI"'
    assert_equal '"HI"', source("'HI'")
  end

  def test_can_source_strings_with_escape_chars
    assert_resource '"\n"'
    assert_resource '"a\nb"'
  end

  def test_can_source_interpolated_strings
    assert_resource '"my name is #{name}"'
    assert_resource '"my name is #{x.a("B")}"'
  end

  def test_can_source_string_concat
    assert_resource '"a" "b"'
    assert_resource '"a" "b" "c"'
    assert_resource '"a" "b" "c" "d"'
  end

  def test_can_source_qwords
    assert_resource '%w{a}'
    assert_resource '%w{a b}'
    assert_resource '%w{a b c}'
    assert_resource '%w{Now is the time for all good men}'
  end

  def test_can_source_words
    assert_resource '%W{a}'
    assert_resource '%W{a b}'
    assert_resource '%W{a b c}'
    assert_resource '%W{Now is the time for all good men}'
  end

  def test_can_source_many_words
    assert_resource '[%w{a b}, %w{c d}]'
    assert_resource '[%W{a b}, %W{c d}]'
  end

  def test_can_source_symbols
    assert_resource ":sym"
  end

  def test_can_source_fancy_symbol_literals
    assert_resource ':"hello, world"'
  end

  def test_can_source_regular_expressions
    assert_resource "/a/"
    assert_resource "/^a$/"
    assert_resource "/a*/"
    assert_resource "/.+/"
    assert_resource "/\./"
    assert_resource "/[a-z]/"
    assert_resource "/\[a-z\]/"
    assert_resource '/#{name}/'
    assert_resource '/before #{name} after/'
  end

  def test_can_source_regular_expressions_with_alternate_delimiters
    assert_resource "%r{a}"
    assert_resource "%r<a>"
    assert_resource "%r[a]"
    assert_resource "%r(a)"
    assert_resource "%r|a|"
  end

  def test_can_source_regular_expressions_with_flags
    assert_resource "%r{a}im"
    assert_resource "/a/i"
  end

  def test_can_source_symbol_quotes
    if RUBY_VERSION >= "2.0"
      assert_resource "%i{a b}"
      assert_resource "%I{a b}"
    end
  end

  def test_can_source_range
    assert_resource "1..10"
    assert_resource "1...10"
  end

  def test_can_source_array_literals
    assert_resource "[]"
    assert_resource "[1]"
    assert_resource "[1]"
    assert_resource "[1, 2]"
    assert_resource "[one, 2, :three, \"four\"]"
  end

  def test_can_source_array_references
    assert_resource "a[1]"
    assert_resource "a.b[1, 4]"
  end

  def test_can_source_object_array_assignments
    assert_resource "obj.a[a] = x"
    assert_resource "obj.a[a, b] = x"
  end

  def test_can_source_hash_literals
    assert_resource "{ }"
    assert_resource "{ :a => 1 }"
    assert_resource "{ :a => 1, :b => 2 }"
  end

  def test_can_source_new_hash_literals
    assert_resource "{ }"
    assert_resource "{ a: 1 }"
    assert_resource "{ a: 1, b: 2 }"
  end

  def test_can_source_mixed_hash_literals
    assert_resource "{ a: 1, :b => 2, c: 3, :d => 4 }"
  end

  def test_can_source_unary_expression
    assert_resource "+1"
    assert_resource "-1"
    assert_resource "+a"
    assert_resource "-a"
    assert_resource "~a"
    assert_resource "!a"
    assert_resource "not a"
  end

  def test_can_source_binary_expressions
    assert_resource "a + 1"
    assert_resource "a + b"
    assert_resource "a - b"
    assert_resource "a * b"
    assert_resource "a / b"
    assert_resource "a && b"
    assert_resource "a || b"
  end

  def test_can_source_trinary_expressions
    assert_resource "a ? b : c"
  end

  def test_can_source_complex_expressions
    assert_resource "a + 1 * 3"
    assert_resource "a + b"
  end

  def test_can_source_expressions_with_parenthesis
    assert_resource "(a + 1) * 3"
    assert_resource "(a + b) + c"
    assert_resource "a + (b + c)"
    assert_resource "((a))"
  end

  def test_can_source_assignment
    assert_resource "a = b"
  end

  def test_can_source_object_assignment
    assert_resource "obj.a = b"
  end

  def test_can_source_array_assignments
    assert_resource "a[a] = x"
    assert_resource "a[a, b] = x"
  end

  def test_can_source_operator_assignments
    assert_resource "a += b"
    assert_resource "a -= b"
    assert_resource "a *= b"
    assert_resource "a /= b"
  end

  def test_can_source_lambda
    assert_resource "lambda { a }"
    assert_resource "lambda { |x| a(x) }"
  end

  def test_can_source_defined
    assert_resource "defined?(a)"
  end

  def test_can_source_undef
    assert_resource "undef a"
  end

  def test_can_source_multiple_assignment
    assert_resource "a, b, c = list"
    assert_resource "a = x, y, z"
    assert_resource "a, b, c = 1, 2, 3"
    assert_resource "a, b, *c = 1, 2, 3, 4"
    assert_resource "a, b, *c = 1, 2, *args"
    assert_resource "(a, b), *c = 1, 2, *args"
    assert_resource "a = *b"
    assert_resource "a = *[b, c]"
  end

  def test_can_source_statement_sequences
    assert_resource_lines "a"
    assert_resource_lines "a; b"
    assert_resource_lines "a; b; c"
  end

  def test_can_source_begin_end
    assert_resource_lines "begin end"
    assert_resource_lines "begin~#a; end"
    assert_resource_lines "begin~#a(); end"
    assert_resource_lines "begin~#a; #b; #c; end"
  end

  def test_can_source_begin_rescue_end
    assert_resource_lines "begin~rescue; end"
    assert_resource_lines "begin~rescue E; #b; end"
    assert_resource_lines "begin~rescue => ex; #b; end"
    assert_resource_lines "begin~rescue E => ex; #b; end"
    assert_resource_lines "begin~#a; rescue E => ex; #b; end"
    assert_resource_lines "begin~#a; rescue E, F => ex; #b; end"
    assert_resource_lines "begin~#a; rescue E, F => ex; #b; #c; end"
    assert_resource_lines "begin~rescue E, F => ex; #b; #c; end"
  end

  def test_can_source_begin_ensure_end
    assert_resource_lines "begin~ensure~end"
    assert_resource_lines "begin~ensure~#b; end"
    assert_resource_lines "begin~#a; ensure~#b; end"
    assert_resource_lines "begin~#a; ensure~#b; end"
  end

  def test_can_source_begin_rescue_ensure_end
    assert_resource_lines "begin~rescue; end"
    assert_resource_lines "begin~rescue E; #b; ensure~#c; end"
    assert_resource_lines "begin~rescue => ex; #b; ensure~#c; end"
    assert_resource_lines "begin~rescue E => ex; #b; ensure~#c; end"
    assert_resource_lines "begin~#a; rescue E => ex; #b; ensure~#c; end"
    assert_resource_lines "begin~#a; rescue E, F => ex; #b; ensure~#c; end"
    assert_resource_lines "begin~#a; rescue E, F => ex; #b; #c; ensure~#d; end"
    assert_resource_lines "begin~rescue E, F => ex; #b; #c; ensure~#d; end"
  end

  def test_can_source_rescue_modifier
    assert_resource "a rescue b"
  end

  def test_can_source_if
    assert_resource_lines "if a THEN~#b~end"
  end

  def test_can_source_if_else
    assert_resource_lines "if a THEN~#b~else~#c~end"
  end

  def test_can_source_if_elsif
    assert_resource_lines "if a THEN~#b~elsif c THEN~#d~end"
  end

  def test_can_source_if_elsif_else
    assert_resource_lines "if a THEN~#b~elsif c THEN~#d~else~#e~end"
  end

  def test_can_source_unless
    assert_resource_lines "unless a THEN~#b~end"
  end

  def test_can_source_unless_else
    assert_resource_lines "unless a THEN~#b~else~#c~end"
  end

  def test_can_source_while
    assert_resource_lines "while c; end"
    assert_resource_lines "while c; #body; end"
  end

  def test_can_source_until
   assert_resource_lines "until c; #body end"
  end

  def test_can_source_for
    assert_resource_lines "for a in list; end"
    assert_resource_lines "for a in list; #c~end"
  end

  def test_can_source_break
   assert_resource_lines "while c; #a; #break if b; #c; end"
   assert_resource_lines "while c; #a; #break value if b; #c; end"
  end

  def test_can_source_next
   assert_resource_lines "while c; #a; #next if b; #c; end"
   assert_resource_lines "while c; #a; #next if b; #c; end"
  end

  def test_can_source_case
    assert_resource_lines "case a~when b; #c; end"
    assert_resource_lines "case a~when b; #c when d; #e; end"
    assert_resource_lines "case a~when b; #c when d; #e~else~#f; end"
  end

  def test_can_source_if_modifier
    assert_resource "a if b"
  end

  def test_can_source_unless_modifier
    assert_resource "a unless b"
  end

  def test_can_source_while_modifier
    assert_resource "a while b"
  end

  def test_can_source_until_modifier
    assert_resource "a until b"
  end

  def test_can_source_alias
    assert_resource "alias a b"
  end

  def test_can_source_fail
    assert_resource "fail Err"
    assert_resource "raise Err"
  end

  def test_can_source_retry
    assert_resource "retry"
  end

  def test_can_source_redo
    assert_resource "redo"
  end

  def test_can_source_return
    assert_resource "return"
    assert_resource "return value"
  end

  def test_can_source_super
    assert_resource "super"
    assert_resource "super a"
    assert_resource "super a, b"
    assert_resource "super a, *args"
    assert_resource "super a, *args, &block"
    assert_resource "super()"
    assert_resource "super(a)"
    assert_resource "super(a, b)"
    assert_resource "super(a, *args)"
    assert_resource "super(a, *args, &block)"
  end

  def test_can_source_yield
    assert_resource "yield"
    assert_resource "yield a"
    assert_resource "yield(a)"
  end

  def test_can_source_self
    assert_resource "self"
  end

  def test_can_source_def
    assert_resource_lines "def f(); end"
    assert_resource_lines "def f(a); end"
    assert_resource_lines "def f(a, b); end"
    assert_resource_lines "def f(a, b=1); end"
    assert_resource_lines "def f(a, *args); end"
    assert_resource_lines "def f(a, *args, &block); end"
    assert_resource_lines "def f(a); #x; end"
    assert_resource_lines "def f(a); #x; #y; end"
  end

  def test_can_source_def_without_parens
    assert_resource_lines "def f; end"
    assert_resource_lines "def f; #x; end"
    assert_resource_lines "def f a; end"
    assert_resource_lines "def f b=1; end"
    assert_resource_lines "def f *args; end"
    assert_resource_lines "def f &block; end"
  end

  def test_can_source_capitalized_def
    assert_resource_lines "def F(); end"
  end

  if RUBY_VERSION >= "2.0.0"
    def test_can_source_ruby2_defs
      assert_resource_lines "def f(a, b=1, *args, c: 2, **opts, &block); end"
      assert_resource_lines "def f(a, aa, b=1, bb=2, *args, c: 3, cc: 4, **opts, &block); end"
      assert_resource_lines "def f(c: 3); end"
      assert_resource_lines "def f(**opts); end"
    end
  end

  if RUBY_VERSION >= "2.0.0"
    def test_can_source_ruby2_defs_without_parens
      assert_resource_lines "def f a, b=1, *args, c: 2, **opts, &block; end"
      assert_resource_lines "def f a, aa, b=1, bb=2, *args, c: 3, cc: 4, **opts, &block; end"
      assert_resource_lines "def f **opts; end"
    end
  end

  def test_can_source_def_self
    assert_resource_lines "def self.f; end"
    assert_resource_lines "def self.f(a, *args, &block); #x; #y; end"
    assert_resource_lines "def Mod.f; end"
    assert_resource_lines "def Mod.f(a, *args, &block); #x; #y; end"
  end

  def test_can_source_class_without_parent
    assert_resource_lines "class X; end"
    assert_resource_lines "class X; #x; end"
    assert_resource_lines "class X; #def f(); #end; end"
  end

  def test_can_source_class_with_parent
    assert_resource_lines "class X < Y; end"
    assert_resource_lines "class X < Y; #x; end"
  end

  def test_can_source_class_with_self_parent
    assert_resource_lines "class X < self; end"
  end

  def test_can_source_private_etc_in_class
    assert_resource_lines "class X; #public; #def f(); #end; end"
    assert_resource_lines "class X; #protected; #def f(); #end; end"
    assert_resource_lines "class X; #private; #def f(); #end; end"
    assert_resource_lines "class X; #def f(); #end; #public :f; end"
    assert_resource_lines "class X; #def f(); #end; #protected :f; end"
    assert_resource_lines "class X; #def f(); #end; #private :f; end"
  end

  def test_can_source_module
    assert_resource_lines "module X; end"
    assert_resource_lines "module X; #x; end"
    assert_resource_lines "module X; #def f(); #end; end"
  end

  def test_can_source_BEGIN
    assert_resource_lines "BEGIN { }"
    assert_resource_lines "BEGIN {~#x~}"
    assert_resource_lines "BEGIN {~#x; #y~}"
  end

  def test_can_source_END
    assert_resource_lines "END { }"
    assert_resource_lines "END {~#x~}"
    assert_resource_lines "END {~#x; #y~}"
  end

  def test_can_source_then
    assert_resource_lines "Then {~#a == b~}"
    assert_resource_lines "Then {~#a == b; #x~}"
  end

  def test_can_handle_missing_statements
    sexp = [:bodystmt, [:stmts_add, [:stmts_new]], nil, nil, nil]
    assert_equal "", Sorcerer.source(sexp)
  end

end
