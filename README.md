qooxdoo.el
----------

Minor mode for working with [qooxdoo](http://qooxdoo.org) apps. Currently
provides only one function, `qooxdoo-search-api`, bound to `C-c f`, that opens
up the api docs for whatever qooxdoo class is at point.

yasnippets are on the way.

INSTALLATION
------------

This is a little awkward, because you probably don't want to turn this on for
every .js file. The cleanest thing I've found so far is [eproject](https://github.com/jrockway/eproject). Stick
something like:

    (require 'eproject)
    (require 'eproject-extras)
    (define-project-type qooxdoo (generic)
      (and (look-for "generator.py")
      (look-for "Manifest.json")
      (look-for "config.json"))
      :relevant-files ("\\.js$"))

    (defun my-qooxdoo-project-file-visit-hook ()
      (require 'qooxdoo)
      (with-current-buffer (qooxdoo-minor-mode)))

    (add-hook 'qooxdoo-project-file-visit-hook 'my-qooxdoo-project-file-visit-hook)

In your `~/.emacs` and you should be pretty good to go. If you have a better way
of doing this, don't hesitate to let me know.
