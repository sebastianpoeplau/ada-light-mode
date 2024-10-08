;;; ada-light-mode.el --- Light major mode for Ada  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Sebastian Poeplau

;; Author: Sebastian Poeplau <sebastian.poeplau@mailbox.org>
;; Keywords: languages
;; URL: https://github.com/sebastianpoeplau/ada-light-mode
;; Version: 0.2
;; Package-Requires: ((emacs "24.3") (compat "29.1"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a lightweight major mode for the Ada programming language. In
;; contrast to ada-mode, it doesn't require a precompiled parser, and it doesn't
;; do any intensive processing. As a consequence, it is faster but less
;; accurate.

;;; Code:

(require 'compat)                       ; for while-let

(defvar ada-light-mode-keywords
  ;; https://www.adaic.org/resources/add_content/standards/05rm/html/RM-2-9.html
  '("abort" "else" "new" "return" "abs" "elsif" "not" "reverse" "abstract" "end"
    "null" "accept" "entry" "select" "access" "exception" "of" "separate"
    "aliased" "exit" "or" "subtype" "all" "others" "synchronized" "and" "for"
    "out" "array" "function" "overriding" "tagged" "at" "task" "generic"
    "package" "terminate" "begin" "goto" "pragma" "then" "body" "private" "type"
    "if" "procedure" "case" "in" "protected" "until" "constant" "interface"
    "use" "is" "raise" "declare" "range" "when" "delay" "limited" "record"
    "while" "delta" "loop" "rem" "with" "digits" "renames" "do" "mod" "requeue"
    "xor")
  "Keywords of the Ada 2012 language.")

(defvar ada-light-mode--font-lock-rules
  (list (regexp-opt ada-light-mode-keywords 'symbols))
  "Rules for search-based fontification in `ada-light-mode'.
The format is appropriate for `font-lock-keywords'.")

(defvar ada-light-mode-syntax-table     ; used automatically by define-derived-mode
  (let ((table (make-syntax-table)))
    ;; Comments start with "--".
    (modify-syntax-entry ?- ". 12" table)
    ;; Newlines end comments.
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?\r ">" table)
    ;; Backslash is a regular symbol, not an escape character.
    (modify-syntax-entry ?\\ "_" table)
    table)
  "Syntax table used in `ada-light-mode'.")

(defvar ada-light-mode-other-file-alist
  '(("\\.ads\\'" (".adb"))
    ("\\.adb\\'" (".ads")))
  "Value for `ff-other-file-alist' in `ada-light-mode'.")

(defun ada-light-mode--syntax-propertize (start end)
  "Apply syntax properties to the region from START to END."
  ;; Ada delimits character literals with single quotes, but also uses the
  ;; single quote for other purposes. Since character literals are always
  ;; exactly one character long (i.e., there are no escape sequences), we can
  ;; easily find them with a regular expression and change the syntax class of
  ;; the enclosing single quotes to "generic string". This also nicely handles
  ;; the case of '"': generic string delimiters only match other generic string
  ;; delimiters, but not ordinary quote characters (i.e., the double quote).
  (goto-char start)
  (while-let ((pos (re-search-forward "'.'" end t)))
    (put-text-property (- pos 3) (- pos 2) 'syntax-table '(15))
    (put-text-property (- pos 1) pos 'syntax-table '(15))))

(defvar ada-light-mode--imenu-rules
  `(("Functions"
     ,(rx bol
          (* space)
          (? (? "not" (* space)) "overriding" (* space))
          "function"
          (+ space)
          (group (+ (or word (syntax symbol)))))
     1)
    ("Procedures"
     ,(rx bol
          (* space)
          (? (? "not" (* space)) "overriding" (* space))
          "procedure"
          (+ space)
          (group (+ (or word (syntax symbol)))))
     1)
    ("Types"
     ,(rx bol
          (* space)
          (? "sub")
          "type"
          (+ space)
          (group (+ (or word (syntax symbol)))))
     1)
    ("Packages"
     ,(rx bol
          (* space)
          "package"
          (+ space)
          (group (+ (or word (syntax symbol))))
          (+ space)
          "is")
     1))
  "Imenu configuration for `ada-light-mode'.
The format is appropriate for `imenu-generic-expression'.")

(defun ada-light-mode--indent-line ()
  "Indent a single line of Ada code."
  ;; This is a really dumb implementation which just indents to the most recent
  ;; non-empty line's indentation. It's better than the default though because
  ;; it stops there, so that users who want completion on TAB can get it after
  ;; indenting. (The default behavior is to insert TAB characters indefinitely.)
  (let ((indent (save-excursion
                  (beginning-of-line)
                  (if (re-search-backward "^[^\n]" nil t) ; non-empty line
                      (current-indentation)
                    0))))
    (if (<= (current-column) (current-indentation))
        (indent-line-to indent)
      (when (< (current-indentation) indent)
        (save-excursion (indent-line-to indent))))))

;;;###autoload
(define-derived-mode ada-light-base-mode prog-mode "AdaLBase"
  "Base mode for `ada-light-mode' and `gpr-light-mode'."
  ;; Set up commenting; Ada uses "--" followed by two spaces.
  (setq-local comment-use-syntax t
              comment-start "--"
              comment-padding 2)

  ;; Set up fontification.
  (setq-local font-lock-defaults '(ada-light-mode--font-lock-rules nil t)
              syntax-propertize-function #'ada-light-mode--syntax-propertize)

  ;; And finally, configure indentation. Since our indentation function isn't
  ;; particularly good, don't force it upon the user.
  (setq-local standard-indent 3
              tab-width 3               ; used by eglot for range formatting
              indent-line-function 'ada-light-mode--indent-line
              electric-indent-inhibit t))

;;;###autoload
(define-derived-mode ada-light-mode ada-light-base-mode "AdaL"
  "Major mode for the Ada programming language.

It doesn't define any keybindings. In comparison with `ada-mode',
`ada-light-mode' is faster but less accurate."
  (setq-local ff-other-file-alist ada-light-mode-other-file-alist
              imenu-generic-expression ada-light-mode--imenu-rules))

;;;###autoload
(define-derived-mode gpr-light-mode ada-light-base-mode "GPRL"
  "Major mode for GPR project files."
  :syntax-table ada-light-mode-syntax-table)

;; Register the mode for Ada code following GNAT naming conventions.
;;;###autoload
(progn (add-to-list 'auto-mode-alist '("\\.ad[abcs]\\'" . ada-light-mode))
       (add-to-list 'auto-mode-alist '("\\.gpr\\'" . gpr-light-mode)))

;; Configure eglot if available.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '((ada-light-mode :language-id "ada")
                                        "ada_language_server"))

  ;; The Ada Language Server doesn't support formatting .gpr files, but it
  ;; provides completion and detects syntax errors.
  (add-to-list 'eglot-server-programs '((gpr-light-mode :language-id "ada")
                                        "ada_language_server" "--language-gpr"))

  (defun ada-light-other-file ()
    "Jump from spec to body or vice versa using the Ada Language Server."
    (interactive)
    (if-let ((server (eglot-current-server)))
        (eglot-execute-command server
                               "als-other-file"
                               (vector (eglot--TextDocumentIdentifier)))
      (message "%s" "Not connected to the Ada Language Server")))

  ;; The "als-other-file" command used by `ada-light-other-file' requires
  ;; support for the "window/showDocument" server request in eglot; add it if
  ;; necessary.
  (unless (cl-find-method 'eglot-handle-request nil '(t (eql window/showDocument)))
    (cl-defmethod eglot-handle-request
      (_server (_method (eql window/showDocument)) &key uri &allow-other-keys)
      (find-file (eglot--uri-to-path uri))
      (list :success t)))

  (defun ada-light-mode--current-line-empty-p ()
    (save-excursion
      (beginning-of-line)
      (looking-at-p (rx (* space) eol))))

  (defun ada-light-mode--indent-line-eglot ()
    "Indent the current line using the Ada Language Server."
    (interactive)
    (if (ada-light-mode--current-line-empty-p)
        ;; Let's not "indent" empty lines with the language server, it would
        ;; just delete them. Instead, take a guess at the required indentation
        ;; based on the most recent non-empty line.
        (indent-relative t t)
      (condition-case err
          (eglot-format (line-beginning-position) (line-end-position))
        ;; When `eglot-format' fails due to a server issue it signals the
        ;; underlying `jsonrpc-error'. In this case, let's return normally to
        ;; give completion a chance.
        (jsonrpc-error
         (when-let ((msg (alist-get 'jsonrpc-error-message (cdr err))))
           (message "Language server error: %s" msg))
         nil))))

  (defun ada-light-mode--eglot-setup ()
    "Set up `eglot' integration for `ada-light-mode'."
    (when (eq major-mode 'ada-light-mode)
      (if (eglot-managed-p)
          (setq-local indent-line-function 'ada-light-mode--indent-line-eglot
                      electric-indent-inhibit nil)
        (setq-local indent-line-function 'ada-light-mode--indent-line
                    electric-indent-inhibit t))))

  (add-hook 'eglot-managed-mode-hook #'ada-light-mode--eglot-setup))

(provide 'ada-light-mode)
;;; ada-light-mode.el ends here
