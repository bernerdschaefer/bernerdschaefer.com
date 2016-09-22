# bernerdschaefer.com

I put thoughts worth sharing here. For thoughts I probably shouldn't share,
[find me on Twitter][Twitter]. I publish code on [GitHub], including my current
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

## Writing and publishing

Start a new post with:

```
middleman article "Title of post"
```

The post will be visible in development, but not production.

Publish a post by setting the `date` and removing `published` from the post's
frontmatter.

## Deployment and Hosting

The site is hosted on [Netlify]. It provides SSL, CDN distribution, and
caching.

The website is automatically built and deployed by Netlify from the master
branch, via a GitHub webhook.

  [Netlify]: https://www.netlify.com/

## Development

The site was started with [proteus].
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
  [proteus]: http://thoughtbot.github.io/proteus/
