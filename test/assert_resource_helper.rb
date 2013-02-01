module AssertResource

  # Assert that a string can be parsed and then resourced without changes.
  def assert_resource(string, options={})
    assert_equal string, source(string, options)
  end

  # Assert that a string can be resourced properly in all the various
  # output modes:
  #
  # * single line
  # * multi-line
  # * indentation
  #
  # Special markup is supported in the string to indicate different
  # expected output.  The string is expressed in single line mode with
  # the following interpretation:
  #
  # * "; " is expected to be literal in single line mode and a newline
  # in multi-line and indented modes.
  #
  # * "~" is expected to be a space in single line mode and a newline
  # in multi-line and indented modes.
  #
  # * "#" is expected to be a tabbed indent in indent mode and a null
  # string in single line and multi-line modes.
  #
  def assert_resource_lines(string, options={})
    assert_resource_for_mode(
      string,
      options.merge(multiline: false)) { |s|
      for_single_line(s)
    }
    assert_resource_for_mode(
      string,
      options.merge(multiline: true)) { |s|
      for_multi_line(s)
    }
    assert_resource_for_mode(
      string,
      options.merge(indent: true)) { |s|
      for_indented(s)
    }
  end

  # Assert the string is correctly resourced given the options and the
  # block conversion.
  def assert_resource_for_mode(string, options={})
    expectation = yield(string)
    assert_equal expectation, source(expectation, options)
  end

  def for_single_line(string)
    string.
      gsub(/\bTHEN~/, "then ").
      gsub(/~/, " ").
      gsub(/#/,'')
  end

  def for_multi_line(string)
    string.
      gsub(/\b THEN~/, "; ").
      gsub(/~/, "\n").
      gsub(/; /, "\n").
      gsub(/#/,'') + "\n"
  end

  def for_indented(string)
    string.
      gsub(/\b THEN~/, "; ").
      gsub(/~/, "\n").
      gsub(/; /, "\n").
      gsub(/#/,'  ') + "\n"
  end

end
