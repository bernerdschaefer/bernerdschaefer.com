---
date: 2014-12-01
title: Writing Go in Vim
teaser: >
  Learn how to set up Vim for writing Go.
robots: https://robots.thoughtbot.com/writing-go-in-vim
---

I recently needed to update my Vim setup for writing Go (the latest release [no
longer ships with its own Vim plugin][go14-changes]), so I thought I'd take this
chance to document and share how to work productively on Go with Vim.

## Prerequisites

You'll need a working Go installation to make use of the Vim setup we'll look
at. I'd recommend either following Go's [official installation
instructions][install], or, if you're using [Homebrew][homebrew], run `brew
install go`.

Then you'll need to choose the location of your default Go workspace. If you've
never done this before, [How To Write Go Code][writego] will walk you through
the steps to set up your work environment.

## vim-go

[vim-go] seems to be the most popular Vim plugin for working with go, so
that's what we'll use. Follow the [installation instructions][vim-go-install]
(or fetch and add to your runtimepath). Open a new Vim instance and run
`:GoInstallBinaries` to get the necessary go tools we'll need.

Once the plugin is installed, these are some of the features it gives you when
writing Go:

### Formatting (on save)

The default configuration for vim-go is to run `:GoFmt` when a file is saved.
That means if you save this file:

```go
package main

func main() {
fmt.Println("Hello, world!")
}
```

It will be automatically rewritten to the correct form:

```go
package main

func main() {
  fmt.Println("Hello, world!")
}
```

If you change the command used by `:GoFmt` to [goimports], it will also
manage your imports (e.g., by inserting the missing "fmt" import in the above
example):

```vim
" format with goimports instead of gofmt
let g:go_fmt_command = "goimports"
```

Automatically formatting and importing packages on save is a popular choice;
but if you feel it is slowing down Vim or confusing you, you can disable it:

```vim
" disable fmt on save
let g:go_fmt_autosave = 0
```

You can still use `:GoFmt` to manually fix up your code.

### Import management

If you're not using goimports as your formatter (and, sometimes, even if you
are), you'll need to manage your imports list. vim-go provides a few useful
commands for this:

- `:GoImport [path]`: adds `"path"` to the correct place in the list of imports.
- `:GoImportAs [name] [path]`: adds `name "path"` to the correct place in the
  list of imports.
- `:GoDrop [path]`: drops package from the list of imports.
- `:GoImports`: runs goimports on the file.

### Documentation

Go's browser-based documentation tools are great, but it's often useful to have
quick access to the docs you need from within Vim. For that, there's `:GoDoc`.
It displays Go documentation in a split pane, and can be called a few ways:

- `:GoDoc`: with no arguments, this will look up the identifier under the
  cursor; note that it is only able to look up top-level identifiers like
  `fmt.Println`, `os.O_RDONLY`, and `bytes.Buffer`.
- `:GoDoc package`: brings up the documentation for a package; for example
  `:GoDoc fmt`.
- `:GoDoc package name`: brings up the function/type/identifier documentation;
  for example `:GoDoc json/encoding NewEncoder` or `:GoDoc os FileInfo`.

### And more

vim-go provides a number of other commands (like `:GoBuild` and `:GoTest`), as
well as configuration options, so be sure to read through `:help vim-go` to
learn more!

[homebrew]: http://brew.sh/
[install]: http://golang.org/doc/install
[writego]: http://golang.org/doc/code.html
[go14-changes]: http://tip.golang.org/doc/go1.4#misc
[goimports]: http://godoc.org/golang.org/x/tools/cmd/goimports
[vim-go]: https://github.com/fatih/vim-go/
[vim-go-install]: https://github.com/fatih/vim-go/blob/master/README.md#install
[vim-go-example]: https://gist.github.com/bernerdschaefer/10b7ad6e496a6b3e2968
