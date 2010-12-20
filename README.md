qooxdoo.el
==========

Minor mode for working with [qooxdoo](http://qooxdoo.org) apps. Currently
provides only one function, `qooxdoo-search-api`, bound to `C-c f`, that opens
up the api docs for whatever qooxdoo class is at point.

yasnippets are on the way.

INSTALLATION
============

You'll need espect, see <https://github.com/rafl/espect>.

After that, something like:

    (require 'espect)
    (require 'qooxdoo)

    (setq qooxdoo-workspace-path "~/workspace")
    (setq qooxdoo-project-paths
          '("/path/to/project/1"
            "foo/bar/baz/project2"))
    (setq espect-buffer-settings
          '(((:qooxdoo)
             (lambda ()
               (qooxdoo-minor-mode t)))))

in your .emacs should do just fine.

`qooxdoo-workspace-path` should be the path to your root "coding" folder,
assuming you keep one. It's just a slight typing saver.

`qooxdoo-project-paths` should be a list of paths to directories containing
qooxdoo projects. If you're not using `qooxdoo-workspace-path`, these should
be absolute. If you are using `qooxdoo-workspace-path`, these are interpreted
as relative to that.

In your `~/.emacs` and you should be pretty good to go. If you have a better way
of doing this, don't hesitate to let me know.
