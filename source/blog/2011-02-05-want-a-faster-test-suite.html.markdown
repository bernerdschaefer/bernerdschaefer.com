---
title: "Using Devise? Want a faster test suite?"
---

Here's the short version: making your password hashes expensive to compute is
great for production environments, but not so much for your tests.

And now the longer version.

Inspired by some recent
[blog](http://37signals.com/svn/posts/2742-the-road-to-faster-tests)
[posts](http://blog.carbonfive.com/2011/02/02/crank-your-specs/), I decided to
run [perftools.rb](https://github.com/tmm1/perftools.rb/) against my spec suite
to diagnose some slowness.

Low and behold, something really strange appeared at the top of the output:

<div class="highlight">
<pre>
Finished in 109.78 seconds

Total: 12182 samples
    <strong>3542 29.1% 29.1%    3542 29.1% BCrypt::Engine.__bc_crypt</strong>
    2262  18.6%  47.6%     2262  18.6% garbage_collector
    1590  13.1%  60.7%     2488  20.4% Kernel#require
</pre>
</div>

Hm... 29.1% of CPU time spent inside `BCrypt`? Wondering where that might be
coming from, I started digging around and found this:

```ruby
Devise.setup do |config|
  config.stretches = 10
  config.encryptor = :bcrypt
end
```

Ah! According to the documentation for
[bcrypt-ruby](https://github.com/brianmario/bcrypt-ruby) a cost factor of 10
(devise turns `stretches` into cost factor when using bcrypt) is quite slow.
Well, *intentionally* slow: "If an attacker was using Ruby to check each
password, they could check ~140,000 passwords a second with MD5 but only ~450
passwords a second with bcrypt()."

Unfortunately, our test suite is the attacker now: most factories depend on a
user, and each new user we create has to generate one of these expensive
hashes.

So --- what would happen if we replace the bcrypt encryptor with our own
encryptor class:

```ruby
# spec/support/devise.rb
module Devise
  module Encryptors
    class Plain < Base
      class << self
        def digest(password, *args)
          password
        end

        def salt(*args)
          ""
        end
      end
    end
  end
end

Devise.encryptor = :plain
```

And with that in place, let's try running out suite again:

<div class="highlight">
<pre>
Finished in <strong>65.72 seconds</strong>

Total: 8428 samples
    2202  26.1%  26.1%     2202  26.1% garbage_collector
    1484  17.6%  43.7%     2329  27.6% Kernel#require
     684   8.1%  51.9%      684   8.1% IO#write
</pre>
</div>

Success! We managed to save __44 seconds__ by not encrypting user passwords in
the test environment! Next step? Digging into all that time in
`garbage_collector` and `Kernel#require`...
