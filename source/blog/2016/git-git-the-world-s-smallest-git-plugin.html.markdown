---
date: Thu Nov 17 16:11:00 CST 2016
title: "git-git: The World's Smallest Git Plugin"
teaser: >
  I solved the most minor of my daily irritations by writing a git plugin.
  You can do it too!
---

One of the things I do almost every day at my command line is type:

```
$ git git whatever
```

It's easy to do.

Sometimes I'll start typing a Git command, but need to look up how to complete
it, and when I return to the terminal I've forgotten I started typing it and --

```
$ git git rebase
git: 'git' is not a git command. See 'git --help'.

Did you mean this?
	init
```

Or sometimes I will be inside a [gitsh] shell -- where the `git` prefix is
implied -- but still type `git` out of habit[^1]. Oops!

  [gitsh]: https://github.com/thoughtbot/gitsh

I've been putting up with this for years, grumbling to myself, "No, I did not
mean init..." and a few weeks ago decided to do something about it.

The solution turned out to be hiding in the error message I had read so many
times: `'git' is not a git command`. What if it *was* a git command?

## Git Commands

What actually happens when you run `git status`? For a long time, I imagined
the `git` command looked something like this:

```ruby
subcommand = ARGUMENTS.first
arguments = ARGUMENTS.rest

case subcommand
when "status": git_status(arguments)
when "commit": git_commit(arguments)
# ...
else
  abort("'#{subcommand}' is not a git command")
end
```

But Git actually takes a very different approach, motivated by the desire to
make extensions feel natural to use and easy to implement.

Each Git command is implemented as a standalone command named by convention
`git-COMMAND`[^2]. This includes builtin commands like `git status`. You can
see all of them by looking in the `libexec/git-core` directory included with
your Git installation. The location of this directory varies between different
operating systems and installations, but you might find it in `/usr/libexec`,
`/usr/local/libexec`, or (if you've installed Git via Homebrew)
`/usr/local/Cellar/git/VERSION/libexec`,
for example:

```
$ ls /usr/local/Cellar/git/2.9.0/libexec/git-core

git-add
# ...
git-blame
# ...
git-checkout
# ...
git-status
# ... 166 commands in total
```

So the `git` command actually looks more like this:

```ruby
subcommand = ARGUMENTS.first
arguments = ARGUMENTS.rest

if command_exists?("git-#{subcommand}")
  exec("git-#{subcommand}", arguments)
else
  abort("'#{subcommand}' is not a git command")
end
```

When Git checks if the command exists, it looks in the `libexec` directory. But
it also searches for commands on your shell's path, which is how third-party
plugins can extend git's behavior.

## `git-git`

Now that we know how git finds commands, we can implement our new `git`
subcommand. Based on the conventions outlined above, that means we need a new
command called `git-git` on our path.

If you don't already have a place you store your own terminal commands, a good
convention is in `$HOME/bin`. Create the directory with `mkdir -p "$HOME/bin"`,
and add `export PATH="$HOME/bin:$PATH"` to your bash or zsh config so you can
run commands there without typing their full path.

Let's create the `git-git` command and make it executable:

```
$ touch "$HOME/bin/git-git"
$ chmod +x "$HOME/bin/git-git"
```

If we run `git git status` we no longer see an error! But it also doesn't do
anything yet, so let's implement the script.

When we run `git git status`, our `git-git` command is run with the single
argument `status`. So to run the command we intended, we can re-execute `git`
with the arguments to the script. Here's what `git-git` looks like:

```
git "$@"
```

`"$@"` represents all of the arguments passed to the script[^3].

What happens now if we run `git git status`?

```
$ git git status
On branch master
Your branch is up-to-date with 'origin/master'.
nothing to commit, working directory clean
```

Success! It even works if we run `git git git git status`.

We had to learn a good deal about how Git is implemented to get there, but in
the end it only took a single line of scripting to alleviate a daily irritation
and extend `git` with custom behavior!

Check out the [git-git repository on GitHub][git-git] to see the final script
and get instructions to install the extension for your own use.

  [git-git]: https://github.com/bernerdschaefer/git-git

_**Thanks** to [Gabe Berke-Williams](https://twitter.com/gabebw), [Adarsh
Pandit](https://twitter.com/adarshp), and [Rachael
Berecka](https://twitter.com/das_rachaelchen) for reading drafts of this._

[^1]: George Brocklehurst, the creator of gitsh, pointed out that [gitsh can be configured to autocorrect this mistake][autocorrect], which is a nice alternative.

[autocorrect]: https://github.com/bernerdschaefer/dotfiles/commit/1dd5a1d8d8a10ff294047e0ea5a9e7c240fc1c8c#commitcomment-19176460

[^2]: This is a bit of a simplification. A number of core commands, like `git-status` and `git-show` are in fact the same executable as `git`. They are (hard) links to the same command, and Git first checks `$0` (the program's name, like `git-status`) for builtin commands before looking for commands on the path.

[^3]: It's important to use `"$@"`, instead of `$*` or other argument features of bash, because it's the only one that will pass the arguments intact. For example, if you ran `git git add "filename with spaces"`, only `"$@"` will correctly maintain the quotes around the filename.
