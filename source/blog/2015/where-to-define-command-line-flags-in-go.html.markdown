---
date: 2015-06-16
title: Where to Define Command-Line Flags in Go
teaser: >
  The common location to define command-line flags might not be the best.
robots: https://robots.thoughtbot.com/where-to-define-command-line-flags-in-go
---

When building a command-line tool in Go,
you'll eventually want to accept arguments as flags.

If you're using the standard library's [flag package][],
you'll have to decide where in your package
to define your flags.
The only requirement of `flag`
is that the flags be defined
before `flag.Parse()` is called.

  [flag package]: http://golang.org/pkg/flag/

After reviewing many existing packages,
the most common way to define command-line flags
can be demonstrated with this small program:

```go
package main

import (
	"flag"
	"net/http"
)

var (
	httpAddr = flag.String("http", ":5050", "HTTP service address")
)

func main() {
	flag.Parse()
	serve()
}

func serve() {
	http.ListenAndServe(*httpAddr, nil)
}
```

This style defines flags as package variables,
parses them at the start of `main`,
and dereferences their values as necessary
within the package's functions.

But this is not the only way to set up your package's flags.
Consider the following alternative of the program above:

```go
func main() {
	var (
		httpAddr = flag.String("http", ":5050", "HTTP service address")
	)
	flag.Parse()

	serve(*httpAddr)
}

func serve(addr string) {
	http.ListenAndServe(addr, nil)
}
```

In the second version,
we've moved our flag
declaration into the main function.
This is better, because the flag now lives next to
where the flags are parsed.

We also needed to update our `serve` function
to accept the the address to listen on as a parameter.
This is great,
because `serve` no longer depends on package state,
but instead declares all of its dependencies.
Previously,
if we wanted to test `serve`,
we would need to set the flag's value before each test case,
and be careful to reset its value afterward.
For this reason,
we also would not have been able
to run our tests concurrently.
Now each test case can provide its own value
as input to the function,
without worrying about contention or contamination.

Finally,
it's a nice bonus
that we were able to dereference the flag value
before calling `serve`.
Dealing with pointers to builtin types
like `string`, `int`, or `float`
is cumbersome,
and often a smell since they can be `nil`,
or accidentally be modified in unsafe ways.

Now, this doesn't make a huge difference in our small example,
but if you approach all your main methods like this,
you'll arrive at a better (and more testable!) design,
because it forces you to deal explicitly with dependencies,
instead of being able to fall back on external state.
