require 'test/unit'

require 'sorcerer'
require 'ripper'

class SignatureTest < Test::Unit::TestCase

  def test_populate_fields_with_nil
    sig = signature_for("def foo; end")

    assert_nil sig.normal_args
    assert_nil sig.default_args
    assert_nil sig.rest_arg
    assert_nil sig.keyword_args
    assert_nil sig.opts_arg
    assert_nil sig.block_arg
  end

  def test_populate_fields_with_real_args
    sig = signature_for("def foo(a, b=1, *args, &block); end")

    assert_equal [[:@ident, "a", [1, 8]]], sig.normal_args
    assert_equal [[[:@ident, "b", [1, 11]], [:@int, "1", [1, 13]]]], sig.default_args
    assert_equal [:rest_param, [:@ident, "args", [1, 17]]], sig.rest_arg
    assert_nil sig.keyword_args
    assert_nil sig.opts_arg
    assert_equal [:blockarg, [:@ident, "block", [1, 24]]], sig.block_arg
  end

  if RUBY_VERSION >= "2.0"
    def test_populate_fields_with_real_args_in_ruby2
      sig = signature_for("def foo(a, b=1, *args, c: 2, **opts, &block); end")

      assert_equal [[:@ident, "a", [1, 8]]], sig.normal_args
      assert_equal [[[:@ident, "b", [1, 11]], [:@int, "1", [1, 13]]]], sig.default_args
      assert_equal [:rest_param, [:@ident, "args", [1, 17]]], sig.rest_arg
      assert_equal [[[:@label, "c:", [1, 23]], [:@int, "2", [1, 26]]]], sig.keyword_args
      assert_equal [:@ident, "opts", [1, 31]], sig.opts_arg
      assert_equal [:blockarg, [:@ident, "block", [1, 38]]], sig.block_arg
    end
  end

  def test_empty_when_no_args
    sig = signature_for("def foo(); end")
    assert sig.empty?, "should be empty"
  end

  def test_not_empty_when_normal_args
    sig = signature_for("def foo(a); end")
    assert ! sig.empty?, "should not be empty"
  end

  def test_not_empty_when_default_args
    sig = signature_for("def foo(b=1); end")
    assert ! sig.empty?, "should not be empty"
  end

  def test_not_empty_when_rest_arg
    sig = signature_for("def foo(*rest); end")
    assert ! sig.empty?, "should not be empty"
  end

  if RUBY_VERSION >= "2.0"
    def test_not_empty_when_keyword_args
      sig = signature_for("def foo(c: 1); end")
      assert ! sig.empty?, "should not be empty"
    end

    def test_not_empty_when_options_args
      sig = signature_for("def foo(**opts); end")
      assert ! sig.empty?, "should not be empty"
    end
  end

  def test_not_empty_when_block_arg
    sig = signature_for("def foo(&block); end")
    assert ! sig.empty?, "should not be empty"
  end

  private

  def signature_for(string)
    sexp = Ripper::SexpBuilder.new(string).parse
    params = find_params(sexp)
    Sorcerer::Signature.new(params)
  end

  def find_params(sexp)
    if ! sexp.is_a?(Array)
      nil
    elsif sexp.first == :params
      sexp
    else
      sexp.each { |subexp|
        found = find_params(subexp)
        return found if found
      }
      nil
    end
  end

end
