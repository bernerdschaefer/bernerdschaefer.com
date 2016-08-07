---
title: Contributing to Open Source Go Projects
teaser: >
  Use this workflow and you'll have your first contribution to an open source
  Go project merged in no time.
robots: https://robots.thoughtbot.com/contributing-to-open-source-golang-projects
---

I want to walk you through my workflow for contributing to open source Go
projects. If you've contributed to open source projects in other languages, it
should feel familiar, but there are a few special things to look for.

We'll use [thoughtbot's Clearbit client library][clearbit] as an example.

## Set up the project

To start with, we'll need the source code for the project. It's important that
it lives inside the `GOPATH`, so the easiest way to grab the code is with `go
get`:

```
go get github.com/thoughtbot/clearbit
```

We'll do the rest of our work from the project directory:

```
cd $GOPATH/src/github.com/thoughtbot/clearbit
```

Let's make sure we have the required dependencies. Each project will have its
own process for doing this, which is hopefully covered in the project
documentation.

Our Go projects ship with a setup script for getting the project ready for
development:

```
bin/setup
```

Now let's check that the tests pass. For the clearbit project, that's:

```
go test ./...
```

Success! The project is now ready for development, and we can start working on
our changes.

## Make your changes

The next step is to fork the project, so we can eventually make a pull request.
If you use [GitHub's hub command][hub], you can run:

```
hub fork
```

This will fork the project, and set up a git remote pointing to your new fork.
You can also fork the project on GitHub and add the remote yourself:

```
git remote add GITHUB_USERNAME \
  https://github.com/GITHUB_USERNAME/clearbit
```

It's important to fork the project and use the git remote in this way, instead
of forking and cloning into another location, so that the project's import
statements still work.

Now it's time to fix the bug or add the feature that prompted you to
contribute. For me, that means [firing up Vim to write some Go][vim-go] but
[there are plenty of alternative editors][editors].

You'll want to make sure that whatever editor you're using runs `gofmt` on
save, as most projects assume your code is correctly formatted before it gets
to code review. `vim-go` does this by default.

In addition to running the tests to validate your changes, there are a few
other tools you may want to run against your code.

For the clearbit project, there's a script which checks that all files are
formatted correctly and pass `go vet`:

```
bin/vet
```

You also might consider running [Golint] on your changes to check its style.
Different projects have different policies about linter warnings. The clearbit
project [uses Hound to run Golint on pull requests][hound], so it's okay if you
skip this while developing.

[There are many other linters][linters], so check which ones your project
expects to be run, as that will make the review process easier.

The rest of the process isn't specific to Go: [write good commit messages, push
your changes to your fork, and submit a pull request][pr].

If you follow these steps, you should have great success getting your changes
through the review process and into the next release!

  [Golint]: https://github.com/golang/lint
  [clearbit]: https://github.com/thoughtbot/clearbit
  [editors]: https://github.com/golang/go/wiki/IDEsAndTextEditorPlugins
  [hound]: https://robots.thoughtbot.com/go-hound-and-code-review-comments
  [hub]: https://github.com/github/hub
  [linters]: https://github.com/alecthomas/gometalinter
  [pr]: https://github.com/thoughtbot/guides/tree/master/protocol/git#write-a-feature
  [vim-go]: https://robots.thoughtbot.com/writing-go-in-vim
