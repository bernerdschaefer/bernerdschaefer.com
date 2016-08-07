---
date: 2015-08-28
title: Configure CircleCI for Go
teaser: >
  We've settled on a `circle.yml` for Go projects.
robots: https://robots.thoughtbot.com/configure-circleci-for-go
---

One of the things I love about [CircleCI]
is how easy it is to get started with any language:
just turn it on!

  [CircleCI]: https://circleci.com

But for working with Go,
like with [Travis CI],
I find that a bit of customization
creates an even better CI experience.

  [Travis CI]: https://robots.thoughtbot.com/configure-travis-ci-for-go

For reference,
here's a complete `circle.yml` configuration
which should work well
for any project using [godep].

  [godep]: https://github.com/tools/godep

```yml
machine:
  environment:
    IMPORT_PATH: "github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"

dependencies:
  pre:
    - go get github.com/tools/godep

  override:
    - mkdir -p "$GOPATH/src/$IMPORT_PATH"
    - rsync -azC --delete ./ "$GOPATH/src/$IMPORT_PATH/"

test:
  pre:
    - go vet ./...

  override:
    - godep go test ./...
```

## Environment setup

We augment our [build environment],
by setting up an environment variable (`IMPORT_PATH`)
for use in later steps.

  [build environment]: https://circleci.com/docs/configuration#environment

We want `IMPORT_PATH` to match our project's
canonical import path,
for example `github.com/foo/bar`;
rather than hard-code this in the configuration,
we can build it from some [standard environment variables]
provided in the CircleCI environment.

  [standard environment variable]: https://circleci.com/docs/environment-variables

## Dependencies

The default dependency step for a Go project
is to run `go get -d -u ./...`.

Since we're using godep to manage our dependencies,
we'll need to override the default steps.

As a prerequisite, then, of setting up our dependencies,
we'll need godep:

```yml
dependencies:
  pre:
    - go get github.com/tools/godep
```

Then we want to override the installation step;
because our dependencies are already vendored,
we don't need to install anything.
This keeps our builds speedy and reliable
and is also recommended for [Heroku deployment].

  [Heroku deployment]: https://devcenter.heroku.com/articles/go-dependencies-via-godep

But we do need to move the current repository
into the right location in the `GOPATH`
which we do with the following steps:

```yml
    - mkdir -p "$GOPATH/src/$IMPORT_PATH"
    - rsync -azC --delete ./ "$GOPATH/src/$IMPORT_PATH/"
```

The `rsync` command will synchronize
the current repository into the correct location in the import path.
The options passed mean:

  * `-a` (`--archive`) is shorthand for a number of other arguments,
    but most importantly makes the sync recursive
    and preserves permissions, owners, etc.
  * `-z` (`--compress`) compresses data during transfer.
  * `-C` (`--cvs-exclude`) excludes various unneeded files.
  * `--delete` removes files in the import path which have been deleted.

At this point, the repository
is fully installed into the `GOPATH`.

## Testing

For running tests,
we're going to make two changes from the default,
which by default runs `go test ./...`.

First, we want to make sure that
that the code passes [`go vet`][go vet] without error.
We're able to wire that in with:

  [go vet]: https://golang.org/cmd/vet/

```yml
test:
  pre:
    - go vet ./...
```

Then we override the test command,
to make it aware of godep:

```yml
  override:
    - godep go test ./...
```

Great!
Now when we open a pull request for our project,
CircleCI will check our program for correctness
and then run the tests
using our vendored dependencies.
