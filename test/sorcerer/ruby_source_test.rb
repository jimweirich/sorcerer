#!/usr/bin/env ruby

require 'test/unit'
require 'ripper'
require 'sorcerer'

class RubySourceTest < Test::Unit::TestCase
  def source(string, debug=false)
    if debug
      puts
      puts "************************************************************"
    end
    sexp = Ripper::SexpBuilder.new(string).parse
    RubySource.new(sexp, debug).source
  end

  def test_can_source_variables
    assert_resource "a"
    assert_resource "b"
  end

  def test_can_source_constants
    assert_resource "A"
    assert_resource "Mod::X"
    assert_resource "Mod::NS::Y"
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

  def test_can_source_method_without_explicit_poetry_mode
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

  def test_can_source_method_with_do_block
    assert_resource "meth do end"
    assert_resource "meth do |a| end" 
    assert_resource "meth(x, y, *rest, &code) do |a, b=1, c=x, *args, &block| one; two; three end"
  end

  def test_can_source_method_with_block
    assert_resource "meth { }"
    assert_resource "meth { |a| }" 
    assert_resource "meth { |a, b| }"
    assert_resource "meth { |*args| }"
    assert_resource "meth { |a, *args| }"
    assert_resource "meth { |&block| }"
    assert_resource "meth { |*args, &block| }"
    assert_resource "meth { |a, b, *args, &block| }"
    assert_resource "meth { |a, b=1, *args, &block| }"
    assert_resource "meth { |a, b=1, c=x, *args, &block| }"
  end

  def test_can_source_method_with_block_contents
    assert_resource "meth { |a| a.x }"
    assert_resource "meth { |a| a.x; b.z }"
  end

  def test_can_source_method_with_complex_args_and_block
    assert_resource "meth(x, y, *rest, &code) { |a, b=1, c=x, *args, &block| one; two; three }"
  end

  def test_can_source_stabby_procs
    assert_resource "->() { }"
    assert_resource "->(a) { }"
    assert_resource "->(a, b) { }"
    assert_resource "->(a, *args) { }"
    assert_resource "->(a, *args, &block) { }"
    assert_resource "->(a) { b }"
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
    assert_resource "/#{name}/"
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
    assert_resource "{}"
    assert_resource "{:a => 1}"
    assert_resource "{:a => 1, :b => 2}"
  end

  def test_can_source_unary_expression
    assert_resource "+1"
    assert_resource "-1"
    assert_resource "+a"
    assert_resource "-a"
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
  end

  def test_can_source_statement_sequences
    assert_resource "a"
    assert_resource "a; b"
    assert_resource "a; b; c"
  end

  def test_can_source_begin_end
    assert_resource "begin; end"
    assert_resource "begin; a; end"
    assert_resource "begin; a(); end"
    assert_resource "begin; a; b; c; end"
  end

  def test_can_source_begin_rescue_end
    assert_resource "begin; rescue; end"
    assert_resource "begin; rescue E => ex; b; end"
    assert_resource "begin; a; rescue E => ex; b; end"
    assert_resource "begin; a; rescue E, F => ex; b; end"
    assert_resource "begin; a; rescue E, F => ex; b; c; end"
    assert_resource "begin; rescue E, F => ex; b; c; end"
  end

  def test_can_source_begin_ensure_end
    assert_resource "begin; ensure end"
    assert_resource "begin; ensure b; end"
    assert_resource "begin; a; ensure b; end"
    assert_resource "begin; a; ensure ; b; end"
  end

  def test_can_source_begin_rescue_ensure_end
    assert_resource "begin; rescue; end"
    assert_resource "begin; rescue E => ex; b; ensure c; end"
    assert_resource "begin; a; rescue E => ex; b; ensure c; end"
    assert_resource "begin; a; rescue E, F => ex; b; ensure c; end"
    assert_resource "begin; a; rescue E, F => ex; b; c; ensure d; end"
    assert_resource "begin; rescue E, F => ex; b; c; ensure d; end"
  end

  def test_can_source_rescue_modifier
    assert_resource "a rescue b"
  end

  def test_can_source_if
    assert_resource "if a then b end"
  end

  def test_can_source_if_else
    assert_resource "if a then b else c end"
  end

  def test_can_source_if_elsif_else
    assert_resource "if a then b elsif c then d else e end"
  end

  def test_can_source_if_elsif
    assert_resource "if a then b elsif c then d end"
  end

  def test_can_source_unless
    assert_resource "unless a then b end"
  end

  def test_can_source_unless_else
    assert_resource "unless a then b else c end"
  end

  def test_can_source_while
   assert_resource "while c do body end"
  end

  def test_can_source_until
   assert_resource "until c do body end"
  end

  def test_can_source_for
    assert_resource "for a in list do end"
    assert_resource "for a in list do c end"
  end

  def test_can_source_break
   assert_resource "while c do a; break if b; c end"
   assert_resource "while c do a; break value if b; c end"
  end

  def test_can_source_next
   assert_resource "while c do a; next if b; c end"
  end

  def test_can_source_case
    assert_resource "case a when b; c end"
    assert_resource "case a when b; c when d; e end"
    assert_resource "case a when b; c when d; e else f end"
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
    assert_resource "def f a; end"
    assert_resource "def f(); end"
    assert_resource "def f(a); end"
    assert_resource "def f(a, b); end"
    assert_resource "def f(a, *args); end"
    assert_resource "def f(a, *args, &block); end"
    assert_resource "def f(a); x; end"
    assert_resource "def f(a); x; y; end"
  end

  def test_can_source_class
    assert_resource "class X; end"
    assert_resource "class X; x; end"
    assert_resource "class X; def f(); end; end"
  end

  def test_can_source_class_with_parent
    assert_resource "class X < Y; end"
    assert_resource "class X < Y; x; end"
  end

  def test_can_source_class_with_self_parent
    assert_resource "class X < self; end"
  end

  def test_can_source_private_etc_in_class
    assert_resource "class X; public; def f(); end; end"
    assert_resource "class X; protected; def f(); end; end"
    assert_resource "class X; private; def f(); end; end"
    assert_resource "class X; def f(); end; public :f; end"
    assert_resource "class X; def f(); end; protected :f; end"
    assert_resource "class X; def f(); end; private :f; end"
  end

  def test_can_source_module
    assert_resource "module X; end"
    assert_resource "module X; x; end"
    assert_resource "module X; def f(); end; end"
  end

  def test_can_source_BEGIN
    assert_resource "BEGIN { }"
    assert_resource "BEGIN { x }"
    assert_resource "BEGIN { x; y }"
  end

  def test_can_source_END
    assert_resource "END { }"
    assert_resource "END { x }"
    assert_resource "END { x; y }"
  end

  def test_can_source_then
    assert_resource "Then { a == b }"
  end

  private

  def assert_resource(string, debug=nil)
    assert_equal string, source(string, debug)
  end
  
end
