# A lightweight Ada mode for Emacs

`ada-light-mode` is a very light alternative to
[`ada-mode`](https://www.nongnu.org/ada-mode/). It depends only on the `compat`
library for compatibility with older Emacs versions, and it aims to be easy to
set up, fast, and reliable.

## Features

- Highlight reserved words of the language
- Identify comments and strings, so that you can use the usual commands for
  (un)commenting, as well as Emacs features for spell-checking, URL detection,
  etc.
- Imenu support for subprograms, packages, and types

You can combine `ada-light-mode` with the [Ada language
server](https://github.com/AdaCore/ada_language_server) for more advanced
features (see below).

## Language server integration

The [Ada language server](https://github.com/AdaCore/ada_language_server) can
enhance `ada-light-mode` with LSP features like documentation lookup,
jump-to-definition, refactoring, and on-the-fly error checking. This section
documents how to set it up with [`eglot`](https://github.com/joaotavora/eglot);
the alternative [`lsp-mode`](https://emacs-lsp.github.io/lsp-mode/) should work
too but will require additional work.

First, install `eglot` (e.g., via `M-x package-install RET eglot RET`) and make
sure that the `ada_language_server` binary is on your `PATH`. Then, create a
`.dir-locals.el` file in your project to tell the language server where to find
the Ada project definition:

``` emacs-lisp
;;; Directory Local Variables
;;; For more information see (info "(emacs) Directory Variables")

((ada-light-mode . ((eglot-workspace-configuration . (:ada
                                                      (:projectFile "/path/to/project.gpr"))))))
```

Finally, open a source file and run `M-x eglot` to start the language server.

When `eglot` is active, indentation uses the language server's formatting
capabilities to indent code (i.e.,
[`textDocument.rangeFormatting`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_rangeFormatting)).
It actually does a bit more than that, possibly breaking the to-be-indented
line up into multiple lines if that's how the language server suggests to
format it. Note that the Ada language server sometimes modifies code beyond the
current line in response to such a request. This can be especially confusing
when you simply inserted a newline - automatic indentation of the just-finished
line triggers the undesired behavior. In such cases, you can insert the newline
with `C-j` to circumvent automatic indentation.

The Ada language server uses on-type formatting to insert space characters
whenever you type a newline. This behavior doesn't work well with Emacs' own
indentation logic; the language server's space characters end up _after_ point.
You may want to disable on-type formatting to work around this issue:

``` emacs-lisp
(push :documentOnTypeFormattingProvider eglot-ignored-server-capabilities)
```

The Ada language server exposes a custom command `als-other-file` that lets you
jump between specification and body files; use it with `M-x
ada-light-other-file` (after starting `eglot`) or bind the command to a key for
easy access.

## License

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <https://www.gnu.org/licenses/>.
