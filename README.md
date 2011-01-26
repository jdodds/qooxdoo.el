qooxdoo.el
==========

Minor mode for working with [qooxdoo](http://qooxdoo.org) apps. Currently, there
is:

+ a function`qooxdoo-search-api`, bound to `C-c C-f`, that opens up the api docs
  for whatever qooxdoo class is at point. 
  
+ support for automatically running `generate.py source` via `compile` on file-save.

yasnippets are on the way.

INSTALLATION
============

You'll need [eproject](https://github.com/jrockway/eproject)

After that, just `(require 'qooxdoo)` in your .emacs, and you're good to go.

This is under heavy development at the moment, the best documentation is the source.
