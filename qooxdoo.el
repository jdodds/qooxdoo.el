;;; qooxdoo.el --- helper functions for working with qooxdoo

;; Copyright (C) 2010  Jeremiah Dodds

;; Author: Jeremiah Dodds <jdd@destructor.neo.rr.com>
;; Keywords: convenience, docs

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:

;;;###autoload
(defgroup qooxdoo nil
  "Minor mode `qooxdoo-mode' for working with qooxdoo libs"
  :prefix "qooxdoo-"
  :group 'convenience)

(defcustom qooxdoo-api-url "http://demo.qooxdoo.org/current/apiviewer/#"
  "URL where the qooxdoo api lives"
  :type 'string
  :group 'qooxdoo)

(defun qooxdoo-search-api ()
  "Bring up the qooxdoo docs for the function at point"
  (interactive)
  (browse-url (concat qooxdoo-search-url (current-word t))))

(provide 'qooxdoo)
;;; qooxdoo.el ends here
