# frozen_string_literal: true

module Hanami
  class Assets
    # Rack middleware for serving assets in development
    #
    # @api public
    # @since 0.1.0
    class Middleware
      # @api private
      # @since 0.1.0
      def initialize(app, assets)
        @app = app
        @assets = assets
      end

      # @api private
      # @since 0.1.0
      def call(env)
        request = Rack::Request.new(env)

        # Check if this is an asset request
        if asset_request?(request.path)
          serve_asset(request.path)
        else
          @app.call(env)
        end
      end

      private

      def asset_request?(path)
        path.start_with?(@assets.config.path_prefix)
      end

      def serve_asset(path)
        # Remove the path prefix to get the logical path
        logical_path = path.sub(@assets.config.path_prefix + "/", "")

        begin
          # Try to find the asset first
          sprockets_asset = @assets.environment.find_asset(logical_path)

          # If not found and looks like a fingerprinted asset, try stripping the fingerprint
          if !sprockets_asset && logical_path.match(/-[a-f0-9]+(\.[^.]+)$/)
            base_name = logical_path.sub(/-[a-f0-9]+(\.[^.]+)$/, '\1')
            sprockets_asset = @assets.environment.find_asset(base_name)
            logical_path = base_name if sprockets_asset
          end
          if sprockets_asset
            headers = {
              'Content-Type' => sprockets_asset.content_type,
              'Content-Length' => sprockets_asset.bytesize.to_s,
              'ETag' => %("#{sprockets_asset.etag}"),
              'Cache-Control' => 'public, max-age=31536000'
            }

            [200, headers, [sprockets_asset.source]]
          else
            [404, { 'Content-Type' => 'text/plain' }, ['Asset not found']]
          end
        rescue => e
          [500, { 'Content-Type' => 'text/plain' }, ["Asset error: #{e.message}"]]
        end
      end
    end
  end
end