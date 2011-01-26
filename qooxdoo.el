;;; qooxdoo.el --- helper functions for working with qooxdoo

;; Author: Jeremiah Dodds <jeremiah.dodds@gmail.com>
;; Keywords: convenience, docs

;; Copyright (C) 2011,  Jeremiah Dodds
;; All rights reserved.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:

;; Redistributions of source code must retain the above copyright notice, this
;; list of conditions and the following disclaimer.  Redistributions in binary
;; form must reproduce the above copyright notice, this list of conditions and
;; the following disclaimer in the documentation and/or other materials provided
;; with the distribution.  Neither the name of Jeremiah Dodds nor the names
;; of its contributors may be used to endorse or promote products derived from
;; this software without specific prior written permission.

;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;; POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; You'll need espect, see <https://github.com/rafl/espect>.

;; After that, something like:

;; (require 'espect)
;; (require 'qooxdoo)
;;
;; (setq qooxdoo-workspace-path "~/workspace")
;; (setq qooxdoo-project-paths
;;       '("/path/to/project/1"
;;         "Foo/bar/baz/project2"))
;; (setq espect-buffer-settings
;;       '(((:qooxdoo)
;;          (lambda ()
;;            (qooxdoo-minor-mode t)))))

;; in your .emacs should do just fine.

;; `qooxdoo-workspace-path' should be the path to your root "coding" folder,
;; assuming you keep one. It's just a slight typing saver.

;; `qooxdoo-project-paths' should be a list of paths to directories containing
;; qooxdoo projects. If you're not using `qooxdoo-workspace-path', these should
;; be absolute. If you are using `qooxdoo-workspace-path', these are interpreted
;; as relative to that.

;;; Code:

;;;###autoload
(defgroup qooxdoo nil
  "Convenience functions for working with qooxdoo apps"
  :prefix "qooxdoo-"
  :group 'convenience)

(defcustom qooxdoo-mode-string-format " [%s]"
  "Format for the mode string. It should start with a space."
  :group 'qooxdoo
  :type 'string)

(defcustom qooxdoo-mode-name (format qooxdoo-mode-string-format "qx")
  "The string to display as the name of qooxdoo-minor-mode")

(defcustom qooxdoo-api-url "http://demo.qooxdoo.org/current/apiviewer/#"
  "URL where the qooxdoo api lives"
  :type 'string
  :group 'qooxdoo)

(defcustom qooxdoo-workspace-path nil
  "If you store your code under a shared root, you can put it here"
  :type 'string
  :group 'qooxdoo)

(defcustom qooxdoo-project-paths nil
  "A list of paths containing qooxdoo projects.
These are prefixed with `qooxdoo-workspace-path'"
  :type 'list
  :group 'qooxdoo)

(defcustom qooxdoo-default-generate-job "source"
  "The default job to have generate.py run"
  :type 'string
  :group 'qooxdoo)

;; thingatpt and api search utils
(require 'thingatpt)
(defun qooxdoo-bounds-of-qooxdoo-at-point ()
  "Return the (possibly chained) class heirarchy at point"
  (save-excursion
    (skip-chars-backward "$0-9a-zA-z\._")
    (if (looking-at "[$0-9a-zA-z._]+")
        (cons (point)
              (match-end 0))
      nil)))

(put 'qooxdoo 'bounds-of-thing-at-point
     'qooxdoo-bounds-of-qooxdoo-at-point)

(defun qooxdoo-search-api ()
  "Bring up the qooxdoo docs for the function at point"
  (interactive)
  (browse-url (concat qooxdoo-api-url (thing-at-point 'qooxdoo))))

;; eproject setup, allows us to load when appropriate and provides a nice point
;; for adding criteria-specific behaviours
(require 'eproject)
(require 'eproject-extras)

(define-project-type qooxdoo (generic)
  (look-for "generate.py")
  :relevant-files ("\\.js")
  :irrelevant-files ("cache/" "source/script/" "inspector/" "build/")
  :main-file "Application.js")

(add-hook 'qooxdoo-project-file-visit-hook
          'qooxdoo-minor-mode-on)

(defun qooxdoo--parse-errors-filename-function (filename)
  (format "%s.js" (expand-file-name
                   (replace-regexp-in-string "\\." "/" filename)
                   qooxdoo-project-code-root)))

(defvar qooxdoo-project-code-root nil)


(defvar qooxdoo-mode-keymap (make-keymap)
  "keymap for qooxdoo-mode")
(define-key qooxdoo-mode-keymap (kbd "C-c f") 'qooxdoo-search-api)

;;;###autoload
(define-minor-mode qooxdoo-minor-mode
  nil                 ;default docstring
  nil                 ;initial value
  qooxdoo-mode-name   ;mode line indicator
  qooxdoo-mode-keymap ;keymap
  :group 'qooxdoo)

(defun qooxdoo-minor-mode-on ()
  (interactive)
  (qooxdoo-minor-mode t)
  (set (make-local-variable 'compile-command)
       (format "%sgenerate.py %s" (eproject-root) qooxdoo-default-generate-job))
  (setq compilation-read-command nil)
;;  (setq compilation-ask-about-save nil)
  (setq compilation-auto-jump-to-first-error t)
  (setq compilation-scroll-output t)
  (setq qooxdoo-project-code-root (expand-file-name "source/class/" (eproject-root)))
  (add-hook 'after-save-hook
            '(lambda ()
               (with-current-buffer (buffer-name)
                 (call-interactively 'compile)))
            nil t)
  (setq compilation-parse-errors-filename-function 'qooxdoo--parse-errors-filename-function)
  (add-to-list 'compilation-search-path (format "%s%s" (eproject-root) "source/class/"))
  (add-to-list 'compilation-error-regexp-alist 'qooxdoo)
  (add-to-list 'compilation-error-regexp-alist-alist
               '(qooxdoo
                 "[ .*-]+\\(Expected[^.]+\\)\. file:\\([^,]+\\), line:\\([^,]+\\), column:\\(.+\\)"
                 2 3 4 2 1)))


(defun qooxdoo-minor-mode-off ()
  (interactive)
  (qooxdoo-minor-mode nil))

(provide 'qooxdoo)
;;; qooxdoo.el ends here
