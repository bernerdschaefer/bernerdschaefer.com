---
title: "Laptop Driven Development"
---

Any time someone sees me working on my (1st generation) Macbook Air, I get
asked, "Do you do actual development on that?" And the answer is, "Absolutely!"
It's been my primary work / personal machine since I got it. I wanted to share
my latest preferred workflow, for anyone else frustrated by developing on a
laptop.

For me, the key is getting as much out of my shell, and avoiding all possible
context switches. Screen real-estate is sacred -- there's no room for two
terminal sessions side-by-side, and even tabs take up precious space.

For those who just want the answer: use `\C-z` and set up bindings to jump back
to where you were.

## Setup

For me, the ideal setup requires just two additional lines in `~/.bash_profile`:

```bash
# ~/.bash_profile
export HISTIGNORE="fg*"
bind '"\C-f": "fg %-\n"'
```

The first line tells bash to omit any commands that start with `fg` from the
history. This will come in handy later. The second line sets up a readline
binding to foreground the process. We're not using a simple `fg` or `fg %`,
because we want to be able to swap back and forth between multiple processes,
which is exactly what `fg %-` gets us.

## Use Case #1: switch between your editor and a short-lived process.

So you're writing an integration test with Capybara, and you can't remember
what the API is to visit a particular page (I know, bear with me).

![Editing integration test in vim](/assets/images/laptop-driven-development/editing-in-vim.png)

Normally you might open a new tab, navigate to the project's directory, and
then `bundle open capybara`.

But we can do better than that! Let's send `C-z` (or `:stop`) to the current
process.

![Return to the console](/assets/images/laptop-driven-development/back-to-the-console.png)

Okay. So now we can `bundle open capybara`, poke around the source, and see,
"Oh, duh! It's 'visit'!" So we close it up, and then jump back into our code
using the binding we set up before (`\C-f`).

![Now we're back where we were](/assets/images/laptop-driven-development/editing-in-vim.png)

And we're right back where we started!

This technique is also incredibly useful for running specs. `\C-z` to get back
to the console, run the spec, and then `\C-f` to get back to your spec. If
you've forgotten what line a failure occured on, just do `:!` to see the terminal's
history. And since we ignored `fg` commands, when we want to run the spec
again, it's as simple as `\C-z` `\C-p` `<enter>` (or `\C-j` if you want to be
fancy).

## Use Case #2: switch between your editor and another process.

The use case here might be for testing out some changes from an `irb` or `rails
console` session.

![An IRB session](/assets/images/laptop-driven-development/irb-session.png)

And... what's that method again? Easy! `\C-z` and `\C-f` to hop back to vim.

![Back to VIM session](/assets/images/laptop-driven-development/my-app-vim-session.png)

Oh, yeah! `\C-z` and `\C-f` and you're back at your IRB prompt.

![Back to the IRB session](/assets/images/laptop-driven-development/irb-session2.png)

And that's it! I have found this to be a much more pleasant and productive way to
work on a laptop than, say, switching between an external editor and the console, or
even running commands in a separate tab from vim. And remember, with
`vim-fugituve`, you don't need to leave vim to commit and push your code!
