# Hanami::Sprockets

Drop-in replacement for hanami-assets that uses Sprockets (like Rails) instead of npm/Node.js.

If you want the Rails asset pipeline in your Hanami app without dealing with npm, this is for you.

## What you get

- Rails-style Sprockets asset pipeline
- No npm/package.json required
- Works with existing Sprockets gems (sassc-rails, coffee-rails, etc.)
- Same API as hanami-assets
- Asset fingerprinting and precompilation
- Development middleware for serving assets

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hanami-sprockets'
```

And then execute:

```bash
$ bundle install
```

## Basic Usage

### Configuration

```ruby
require 'hanami-sprockets'

# Basic configuration
config = Hanami::Assets::Config.new(
  path_prefix: "/assets",
  digest: true,  # Enable fingerprinting for production
  subresource_integrity: [:sha256]  # Enable SRI
)

# Create assets instance
assets = Hanami::Assets.new(
  config: config,
  root: "/path/to/your/app"
)
```

### Asset Structure

Follow Rails conventions:

```
app/
├── assets/
│   ├── stylesheets/
│   │   └── app.css
│   ├── javascripts/
│   │   └── app.js
│   └── images/
│       └── logo.png
├── lib/
│   └── assets/
└── vendor/
    └── assets/
```

### CSS Image References

Reference images in CSS using ERB and the `asset_path` helper:

```css
/* app.css.erb */
.header {
  background-image: url('<%= asset_path("logo.png") %>');
}
```

This generates fingerprinted URLs automatically in production. Plain CSS with relative paths also works:

```css
/* Plain CSS */
.simple {
  background-image: url('../images/logo.png');
}
```

### Development Server

Add the middleware to your Rack stack:

```ruby
use Hanami::Assets::Middleware, assets
```

### Using Assets

```ruby
# Get an asset
asset = assets["app.css"]
puts asset.url  # => "/assets/app-abc123def.css"
puts asset.path # => "/assets/app-abc123def.css"
puts asset.sri  # => "sha256-..."

# Check if asset exists
begin
  asset = assets["missing.css"]
rescue Hanami::Assets::AssetMissingError
  puts "Asset not found"
end
```

### Template Helpers

Include the helpers in your templates:

```ruby
class MyView
  include Hanami::Assets::Helpers

  private

  def hanami_assets
    @hanami_assets # Inject your assets instance
  end
end
```

Then use them in templates:

```erb
<!DOCTYPE html>
<html>
<head>
  <%= stylesheet_tag "reset", "app" %>
</head>
<body>
  <%= image_tag "logo", alt: "Logo" %>
  <%= javascript_tag "app", async: true %>
</body>
</html>
```

### Precompilation

For production:

```ruby
# Precompile assets
manifest = assets.precompile("/path/to/public/assets")
puts "Compiled assets:", manifest.assets.keys
```

## Advanced Configuration

```ruby
config = Hanami::Assets::Config.new do |config|
  config.path_prefix = "/assets"
  config.digest = Rails.env.production?
  config.compress = Rails.env.production?
  config.subresource_integrity = [:sha256, :sha512]
  config.base_url = ENV['CDN_URL'] # For CDN support
  config.asset_paths = [
    "vendor/assets/custom",
    "lib/special_assets"
  ]
  config.precompile = %w[
    app.js
    app.css
    *.png
    *.jpg
    *.svg
  ]
end
```

## Adding processors

Just add the gems you want:

```ruby
gem 'sassc-rails'      # SCSS/Sass
gem 'coffee-rails'     # CoffeeScript
gem 'uglifier'         # JS compression
```

## Development vs Production

- **Development**: Assets served on-demand via middleware
- **Production**: Precompile assets with `assets.precompile("/path/to/public/assets")`

## API Reference

### Hanami::Assets

Main class for asset management.

#### Methods

- `#[](path)` - Find and return an asset
- `#precompile(target_dir)` - Precompile assets for production
- `#logical_paths` - Get all available asset paths
- `#subresource_integrity?` - Check if SRI is enabled
- `#crossorigin?(url)` - Check if URL is cross-origin

### Hanami::Assets::Asset

Represents a single asset.

#### Methods

- `#url` - Full URL to asset
- `#path` - Path to asset (without base URL)
- `#sri` - Subresource integrity hash
- `#logical_path` - Original path without fingerprint
- `#digest_path` - Fingerprinted path

### Hanami::Assets::Helpers

Template helpers for generating asset HTML tags.

#### Methods

- `stylesheet_tag(*sources, **options)` - Generate `<link>` tags
- `javascript_tag(*sources, **options)` - Generate `<script>` tags
- `image_tag(source, **options)` - Generate `<img>` tags
- `asset_url(source)` - Get URL for asset
- `asset_path(source)` - Get path for asset

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).