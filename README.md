# Sorcerer -- Recovering the Source

| Master |
| :----: |
| [![Master Build Status](https://secure.travis-ci.org/jimweirich/sorcerer.png?branch=master)](https://secure.travis-ci.org/jimweirich/sorcerer) |

Sorcerer will generate Ruby code from a Ripper-like abstract syntax
tree (i.e. S-Expressions).

Sorcerer is targetted mainly at small snippets of Ruby code,
expressable in a single line. Longer examples may be re-sourced, but
they will be rendered in a single line format.

**Version: 1.0.0**

## Limitations

Sorcerer is only tested on Ruby 1.9 and 2.0.

## Links

| Description            | Link |
| :---:                  | :---: |
| Documents              | http://github.com/jimweirich/sorcerer |
| Git Clone              | git://github.com/jimweirich/sorcerer.git |
| Issues / Bug Tracking  | https://github.com/jimweirich/sorcerer/issues |
| Continuous Integration | http://travis-ci.org/#!/jimweirich/sorcerer |

## Examples

```ruby
  sexp = [:binary,
           [:var_ref, [:@ident, "a", [1, 0]]],
           :+,
           [:var_ref, [:@ident, "b", [1, 4]]]]
  puts Sorcerer.source(sexp)
```

will generate

```ruby
  a + b
```

Ripper may be used to produce the s-expressions used by Sorcerer. The
following will produce the same output.

```ruby
  sexp = Ripper::SexpBuilder.new("a + b").parse
  puts Sorcerer.source(sexp)
```

## Options

### No Options

By default, sorcerer will output its source in single line mode.

For example, given:

```ruby
  sexp = Ripper::SexpBuilder.new("def foo; bar; end").parse
```

Then the following

```ruby
  puts Sorcerer.source(sexp)
```

generates single line output (the default):

```ruby
def foo; bar; end
```

### Multi-Line Output

If you want multi-line output of source, add the multiline option to
the source command.

For example, given the sexp generated above, then this

```ruby
  puts Sorcerer.source(sexp, multiline: true)
```

generates multi-line output

```ruby
def foo
bar
end
```

(Note that all multi-line output will have a final newline.)

### Indentation

By default, sorcerer does not indent its multiline output.  Adding the
"indent" option will cause the output to be indented.

For example, given the sexp generated above, then the following

```ruby
  puts Sorcerer.source(sexp, indent: true)
```

generates indented output:

```ruby
def foo
  bar
end
```

### Debugging Output

If you wish to see the S-Expressions processed by Sorcerer and the
output emitted, then use the debug option:

```ruby
  puts Sorcerer.source(sexp, debug: true)
```

## License

Sorcerer is available under the terms of the MIT license. See the
MIT-LICENSE file for details.

## History

* 1.0.2 - Fix bug in interpolated regular expression resourcing.

* 1.0.1 - Add support for missing exception class or variable in
          rescue (from Trent Ogren).

* 1.0.0 - Ready for the work, version 1!

* 0.3.11 - Fix support for subexpressions involving Meth() calls.

* 0.3.10 - Fix several issues with spaces in argument lists.

* 0.3.9 - Support %i{} and %I{}.

* 0.3.8 - Include constants in sub-expressions.

* 0.3.7 - Include array in sub-expressions.

* 0.3.6 - Support 'defined?'. Suppress nil, true, false in
          sub-expressions.

* 0.3.5 - Add handler for mrhs_new.

* 0.3.4 - Support 'meth a, b'.

* 0.3.3 - Fix unary not.

* 0.3.2 - Support 'def mod.method' syntax.

* 0.3.1 - 1.9.3 support. Indenting stabby procs. RedCloth not required
          for testing.

* 0.3.0 - New hash literal support. Multi-line output always end with
          a newline.

* 0.2.0 - Added support for indented output.

* 0.1.0 - Added support for multi-line output. Improved rendering of a
          number of constructs

* 0.0.7 - Basic single line version
