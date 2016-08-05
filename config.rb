activate :autoprefixer
activate :syntax

set :css_dir, "assets/stylesheets"
set :fonts_dir, "assets/fonts"
set :images_dir, "assets/images"
set :js_dir, "assets/javascripts"
set :layout, "layouts/application"
set :markdown, input: "GFM", hard_wrap: false, footnote_nr: 1
set :markdown_engine, :kramdown
set :relative_links, true

page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

configure :development do
  activate :livereload
end

configure :build do
  activate :relative_assets
end

activate :blog do |blog|
  blog.layout = "article"
  blog.permalink = "{year}/{month}/{day}/{title}.html"
  blog.sources = "blog/{year}-{month}-{day}-{title}.html"
end

activate :deploy do |deploy|
  deploy.build_before = true
  deploy.deploy_method = :git
end
