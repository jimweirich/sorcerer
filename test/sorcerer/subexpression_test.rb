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

  def test_binary_expressions
    assert_subexpressions "a + b", ["a", "b", "a + b"]
    assert_subexpressions("a + b + c",
      ["a", "b", "a + b", "c", "a + b + c"])
  end

  def test_method_calls
    assert_subexpressions "o.f", ["o", "o.f"]
  end

  def test_method_calls
#    assert_subexpressions "o.f", ["o", "o.f"], :dbg
#    assert_subexpressions "o.f(a, b)", ["o", "o.f"], :dbg
  end

  def test_pattern_matching
    assert_subexpressions "a =~ /r/", ["a", "/r/", "a =~ /r/"]
  end

end
