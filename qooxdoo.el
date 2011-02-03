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

;; You'll need eproject, see <https://github.com/jrockway/eproject>.

;; After that, just (require 'qooxdoo) in your .emacs and you should be good to
;; go. By default, "generate.py source" will be run each time you save a file,
;; and there's a handy api lookup variable bound to C-c C-f.

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

(defcustom qooxdoo-default-generate-job "source"
  "The default job to have generate.py run"
  :type 'string
  :group 'qooxdoo)

(defcustom qooxdoo-compile-on-save t
  "Whether or not to auto-run compile when a file in the project is saved"
  :type 'boolean
  :group 'qooxdoo)

(defcustom qooxdoo-compile-read-command nil
  "Whether compile should ask about the command it's about to run"
  :type 'boolean
  :group 'qooxdoo)

(defcustom qooxdoo-compile-ask-about-save t
  "Whether compile should ask about saving buffers that are modified"
  :type 'boolean
  :group 'qooxdoo)

(defcustom qooxdoo-compile-auto-jump-to-first-error t
  "Whether compile should open the first (and in our case, last) error when it
  finds one"
  :type 'boolean
  :group 'qooxdoo)

(defcustom qooxdoo-compile-scroll-output t
  "Whether compile should automatically scroll its output"
  :type 'boolean
  :group 'qooxdoo)

(defcustom qooxdoo-compile-error-alist-alist
  '((qooxdoo-error
     "[ .*-]+\\(Expected[^.]+\\)\. file:\\([^,]+\\), line:\\([^,]+\\), column:\\(.+\\)"
     2 3 4 2 1)
    (qooxdoo-warning-unknown-global-symbol
     "[ .*-]+Warning: Hint: Unknown global symbol referenced: \\([^q][^x][^ ]+\\) (\\([^:]+\\):\\([^)]+\\)"
     2 3 nil 1 1))
  "The alist to send to compile mode. This thing, which you can read all about
  in compile.el, roughly reads like 'match these things in the output from our
  compiler, then takes these numbers to mean 'match number of file name, line
  number, and line column', then 0 for info, 1 for warning, 2 for error, then
  'match number to make a hyperlink'"
  :type 'list
  :group 'qooxdoo)

(defcustom qooxdoo-code-root-prefix "source/class/"
  "The path to where the main source of your app lives, relative to the
  directory containing generate.py. You probably don't need to change this, but
  if you're using a different layout than the qooxdoo default for some reason,
  it might fill your needs.

  This is used when finding which file compile should open for an error, in
  combination with eproject-root and the file reported by the source job"
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

(defun qooxdoo-setup-compilation-mode ()
  (set (make-local-variable 'compile-command)
       (format "%sgenerate.py %s" (eproject-root) qooxdoo-default-generate-job))

  (setq compilation-read-command
        qooxdoo-compile-read-command)

  (setq compilation-ask-about-save
        qooxdoo-compile-ask-about-save)
  
  (setq compilation-auto-jump-to-first-error
        qooxdoo-compile-auto-jump-to-first-error)
  
  (setq compilation-scroll-output
        qooxdoo-compile-scroll-output)
  
  (setq qooxdoo-project-code-root
        (expand-file-name
         qooxdoo-code-root-prefix
         (eproject-root)))

  (if qooxdoo-compile-on-save
      (add-hook 'after-save-hook
                '(lambda ()
                   (with-current-buffer (buffer-name)
                     (call-interactively 'compile)))
                nil t))
  
  (setq compilation-parse-errors-filename-function
        'qooxdoo--parse-errors-filename-function)

  (dolist (regexp-alist qooxdoo-compile-error-alist-alist)
    (add-to-list 'compilation-error-regexp-alist-alist regexp-alist)
    (add-to-list 'compilation-error-regexp-alist (car regexp-alist))))


(defvar qooxdoo-mode-keymap (make-keymap)
  "keymap for qooxdoo-mode")

(define-key qooxdoo-mode-keymap (kbd "C-c C-f") 'qooxdoo-search-api)

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
  (qooxdoo-setup-compilation-mode))

(defun qooxdoo-minor-mode-off ()
  (interactive)
  (qooxdoo-minor-mode nil))

(provide 'qooxdoo)
;;; qooxdoo.el ends here
