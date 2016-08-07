---
date: 2010-06-28
title: "FakeWeb for the Browser"
teaser: >
  Akephalos lets you block and stub external requests
  to keep test suites fast and reliable.
---

Before releasing <a href="http://rubygems.org/gems/akephalos">akephalos-0.0.5</a>, I spent some time attempting to resolve some random failures that were showing up in our real integration suites, but not in capybara or akephalos' specs. Along the way, I realized that because akephalos (and the same goes for selenium) behaves just like a real browser, all of our pages with `<script>` tags for Facebook Connect, Google Analytics, and Google Maps were actually going out over the network to load the data. Even worse, the Google Maps code was being run on every page&#8212;building tiles, placing markers, etc.&#8212;which was killing the performace even though no scenarios actually tested the maps. Perhaps not surprisingly, after disabling these resource-intensive external javascripts, the random failures disappeared.

I decided, then, that we needed something like FakeWeb except for resources requested by the browser itself, and after a bit of digging in the HTMLUnit docs, I was able to wire up what I needed to implement filters for akephalos.

## Akephalos Filters

Configuring filters in akephalos should be familiar to anyone who has used FakeWeb or a similar library. The simplest filter requires only an <abbr>HTTP</abbr> method (`:get`, `:post`, `:put`, `:delete`, `:any`) and a string or regex to match against.

```ruby
Akephalos.filter(:get, "http://www.google.com")

Akephalos.filter(:any, %r{^http://(api\.)?twitter\.com/.*$})
```

By default, all filtered requests will return an empty body with a 200 status code. You can change this by passing additional options to your filter call.

```ruby
Akephalos.filter(:get, "http://google.com/missing",
  :status => 404, :body => "... <h1>Not Found</h1> ...")

Akephalos.filter(:post, "http://my-api.com/resource.xml",
  :status => 201, :headers => {
    "Content-Type" => "application/xml",
    "Location" => "http://my-api.com/resources/1.xml" },
  :body => {:id => 100}.to_xml)
```

And that's really all there is to it! It should be fairly trivial to set up filters for the external resources you need to fake. For reference, however, here's what we ended up using for our external sources.

#### Google Analytics

Google Analytics code is passively applied based on HTML comments, so simply returning an empty response body is enough to disable it without errors.

```ruby
Akephalos.filter(:get, "http://www.google-analytics.com/ga.js",
  :headers => {"Content-Type" => "application/javascript"})
```

#### Facebook Connect

When you enable Facebook Connect on your page, the FeatureLoader is requested, and then additional resources are loaded when you call `FB_RequireFeatures`. We can therefore return an empty function from our filter to disable all Facebook Connect code.

```ruby
Akephalos.filter(:get, "http://static.ak.connect.facebook.com/js/api_lib/v0.4/FeatureLoader.js.php",
  :headers => {"Content-Type" => "application/javascript"},
  :body => "window.FB_RequireFeatures = function() {};")
```

#### Google Maps

Google Maps requires the most extensive amount of API definitions of the three, but these few lines cover everything we've encountered so far.

```ruby
Akephalos.filter(:get, "http://maps.google.com/maps/api/js?sensor=false",
  :headers => {"Content-Type" => "application/javascript"},
  :body => "window.google = {
              maps: {
                LatLng: function(){},
                Map: function(){},
                Marker: function(){},
                MapTypeId: {ROADMAP:1}
              }
            };")
```
