---
date: 2015-06-30
title: Configure Travis CI for Go
teaser: >
  The defaults are useful, but sometimes you need a bit more.
robots: https://robots.thoughtbot.com/configure-travis-ci-for-go
---

The fastest way to get started testing
your Go application with [Travis CI]
is to create a `.travis.yml` with `language: go`
and push to your remote.

The defaults tend to work well
for a broad spectrum of projects.
But it's good to understand
what those defaults do,
and how and why you might want to change them.

  [Travis CI]: https://travis-ci.com/

For reference,
here's a complete `.travis.yml` configuration
which is perfect for an application deployed to [Heroku].
Read on for how we arrived at this,
and other settings you might want to use.

```yml
language: go
sudo: false
before_script:
  - go vet ./...
install:
  # Add Godeps dependencies to GOPATH and PATH
  - export GOPATH="${TRAVIS_BUILD_DIR}/Godeps/_workspace:$GOPATH"
  - export PATH="${TRAVIS_BUILD_DIR}/Godeps/_workspace/bin:$PATH"
```

  [Heroku]: https://www.heroku.com/

## Inside a Go build on Travis CI

When Travis CI receives a push for a Go project,
first it will prepare the environment:

  - use [gimme] to install Go if necessary
  - set up a working `GOPATH`
  - copy the app into the right place in the `GOPATH`

Then there's the install phase:

  - set up `GOPATH` and `PATH` for [godep] if it's detected
  - restore godep dependencies if they're not vendored
  - run `go get -t -v ./...` to fetch dependencies

Finally, there's the script phase:

  - run `go test -v ./...`

I've left out a few branches,
and some less important phases,
but you can learn everything that happens
by reading the source for Travis CI's [Go build script generator].

  [gimme]: https://github.com/meatballhat/gimme
  [Go build script generator]: https://github.com/travis-ci/travis-build/blob/278b9c85c1d17f617a7a2edcfbe2be398a189ca4/lib/travis/build/script/go.rb

## Customize install and build with `gobuild_args`

One way to customize the install phase
is by setting `gobuild_args` in `.travis.yml`.
The default value is `-v`,
but we could adjust our build behavior
in the following ways:

  - Specify a [build tag], like `-tags ci`.
  - Set a string variable, like
    `-X main.Version $(git rev-parse --short HEAD)`
    to set the `Version` string variable to the current git revision.
  - Enable the [race detector] with `-race`.

  [build tag]: http://golang.org/pkg/go/build/#hdr-Build_Constraints
  [race detector]: http://blog.golang.org/race-detector

Note that the value of `gobuild_args`
is only available to the default install and script steps.
If you override one of those,
you would need to specify the flags again.

## Use custom install scripts

If we want more control than build flags,
we'll need to specify our own install steps.

For example, the default install steps
differ from those used by Heroku's [Go buildpack].
This can lead to cases where a build
passes on Travis CI but fails on Heroku!

The default and recommended way
to deploy to Heroku is to use [godep]
to save the project's dependencies.
Because the dependencies are vendored with the repo,
Heroku will not fetch remote dependencies when building a slug.

  [godep]: https://github.com/tools/godep
  [Go buildpack]: https://github.com/heroku/heroku-buildpack-go

But we saw above that even if Travis CI detects godep,
it will run `go get -t -v ./...`,
which means it will install missing dependencies.
So if we forget to run `godep save`,
our build will be green,
but we'll be unable to deploy!

Instead we could set a new install step
to export new `GOPATH` and `PATH` variables
which include the godep workspace:

```yml
install:
  # Add Godeps dependencies to GOPATH and PATH
  - export GOPATH="${TRAVIS_BUILD_DIR}/Godeps/_workspace:$GOPATH"
  - export PATH="${TRAVIS_BUILD_DIR}/Godeps/_workspace/bin:$PATH"
```

Now if we forget to update our dependencies,
the build will fail as expected.

## Customize the script phase

There's definitely much less to unpack here,
since it only runs one command: `go test`.

In fact, it's pretty unlikely you need
to change the script.

One thing you might want to do, though,
is to run some other checks in addition to your tests.
The `before_script` phase is a great place to do this.

For example, it's common for projects to assert
that the code passes [`go vet`][go vet] without error.
You can hook that in with:

```yml
before_script:
  - go vet ./...
```

  [go vet]: https://golang.org/cmd/vet/

Now the build will be rejected if `go vet` returns any errors!

## What else?

With the tools above,
we can perform conditional compilation on CI,
enable Go's race detector,
use vendored dependencies,
and check our code before running the tests.

If you need more than that,
[Building a Go Project] and [Customizing the Build]
are good sources of information provided by Travis CI.

  [Building a Go Project]: http://docs.travis-ci.com/user/languages/go/
  [Customizing the Build]: http://docs.travis-ci.com/user/customizing-the-build/
