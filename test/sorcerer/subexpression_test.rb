require 'test/unit'
require 'sorcerer'
require 'ripper'
require 'pp'

class SubexpressionTest < Test::Unit::TestCase
  def assert_subexpressions code, subexpressions, debug=false
    sexp = Ripper::SexpBuilder.new(code).parse
    if debug
      pp sexp
    end
    sub = Sorcerer::Subexpression.new(sexp)
    assert_equal subexpressions, sub.subexpressions
  end

  def test_simple
    assert_subexpressions "a", ["a"]
    assert_subexpressions "b", ["b"]
  end

  def test_unary_expressions
    assert_subexpressions "-(a+b)", [
      "a", "b", "a + b", "-(a + b)"
    ]
  end

  def test_binary_expressions
    assert_subexpressions "a + b", ["a", "b", "a + b"]
    assert_subexpressions("a + b + c",
      ["a", "b", "a + b", "c", "a + b + c"])
  end

  def test_method_calls_without_args
    assert_subexpressions "o.f", ["o", "o.f"]
    assert_subexpressions "f()", ["f()"]
  end

  def test_method_calls_with_args
    assert_subexpressions "o.f", ["o", "o.f"]
    assert_subexpressions "o.f(a, b)", [
      "a", "b", "o", "o.f(a, b)"
    ]
    assert_subexpressions "f(a, b)", [
      "a", "b", "f(a, b)"
    ]
  end

  def test_array_reference
    assert_subexpressions "a[i]", ["i", "a[i]"]
  end

  def test_array_literal
    assert_subexpressions "[a, b, c]", [
      "a", "b", "c", "[a, b, c]"
    ]
  end

  def test_hash_literal
    assert_subexpressions "{:a => aa, :b => bb}", [
      "aa", "bb", "{:a => aa, :b => bb}"
    ]
  end

  def test_pattern_matching
    assert_subexpressions "a =~ /r/", ["a", "a =~ /r/"]
  end

  def test_complex_expression
    assert_subexpressions "o.f(a+b, c*d, x.y, z(k, 2, 3))", [
      "a", "b", "a + b", "c", "d", "c * d", "x", "x.y", "k", "z(k, 2, 3)",
      "o", "o.f(a + b, c * d, x.y, z(k, 2, 3))"
    ]
  end

end
