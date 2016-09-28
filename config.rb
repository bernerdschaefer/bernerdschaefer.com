activate :autoprefixer
activate :syntax

set :css_dir, "assets/stylesheets"
set :fonts_dir, "assets/fonts"
set :images_dir, "assets/images"
set :js_dir, "assets/javascripts"
set :layout, "layouts/application"
set :markdown, fenced_code_blocks: true, smartypants: true, with_toc_data: true, footnotes: true
set :markdown_engine, :redcarpet
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
  blog.new_article_template = File.expand_path("source/blog/template.erb")
  blog.permalink = "{year}/{month}/{day}/{title}.html"
  blog.sources = "blog/{year}/{title}.html"
end
