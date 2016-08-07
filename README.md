# bernerdschaefer.com

I put thoughts worth sharing here. For thoughts I probably shouldn't share,
[find me on Twitter][Twitter]. I pubish code on [GitHub], including my current
project, [AtmanOS].

[AtmanOS]: http://atmanos.org
[Github]: https://github.com/bernerdschaefer
[Twitter]: https://twitter.com/bjschaefer

## Getting Started

Install the project's dependencies with:

```
bin/setup
```

Run the site locally with:

```
bin/server
```

Stylesheets, fonts, images, and JavaScript files go in the `/source/assets/`
directory.

Vendor stylesheets and JavaScripts should go in each of their `/vendor/`
directories.

Deploy the site to production with:

```
bin/deploy
```

## Development

The site is built with [Middleman], a static site generator. It also uses:

* [Sass (LibSass)](http://sass-lang.com):
  CSS with superpowers
* [Bourbon](http://bourbon.io):
  Sass mixin library
* [Neat](http://neat.bourbon.io):
  Semantic grid for Sass and Bourbon
* [Bitters](http://bitters.bourbon.io):
  Scaffold styles, variables and structure for Bourbon projects.
* [Middleman Live Reload](https://github.com/middleman/middleman-livereload):
  Reloads the page when files change
* [Middleman Deploy](https://github.com/karlfreeman/middleman-deploy):
  Deploy your Middleman build via rsync, ftp, sftp, or git (deploys to Github
  Pages by default)

  [Middleman]: https://middlemanapp.com/
