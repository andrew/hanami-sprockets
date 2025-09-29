# frozen_string_literal: true

module Hanami
  class Assets
    # Represents a single front end asset.
    #
    # @api public
    # @since 0.1.0
    class Asset
      # @api private
      # @since 0.1.0
      attr_reader :config
      private :config

      # Returns the asset's absolute URL path.
      #
      # @example Asset from local dev server
      #   asset.path # => "/assets/app.js"
      #
      # @example Deployed asset with fingerprinted name
      #   asset.path # => "/assets/app-28a6b886de2372ee3922fcaf3f78f2d8.js"
      #
      # @return [String]
      #
      # @api public
      # @since 0.1.0
      attr_reader :path

      # @api private
      # @since 0.1.0
      attr_reader :base_url
      private :base_url

      # Returns the asset's subresource integrity value, or nil if none is available.
      #
      # @return [String, nil]
      #
      # @api public
      # @since 0.1.0
      attr_reader :sri

      # Returns the asset's logical path (original path without fingerprinting)
      #
      # @return [String]
      #
      # @api public
      # @since 0.1.0
      attr_reader :logical_path

      # Returns the asset's digest path (fingerprinted path)
      #
      # @return [String]
      #
      # @api public
      # @since 0.1.0
      attr_reader :digest_path

      # Returns the asset's content type
      #
      # @return [String]
      #
      # @api public
      # @since 0.1.0
      attr_reader :content_type

      # Returns the asset's source content
      #
      # @return [String]
      #
      # @api public
      # @since 0.1.0
      attr_reader :source

      # @api private
      # @since 0.1.0
      def initialize(path:, base_url:, sri: nil, logical_path: nil, digest_path: nil, content_type: nil, source: nil)
        @path = path
        @base_url = base_url
        @sri = sri
        @logical_path = logical_path
        @digest_path = digest_path
        @content_type = content_type
        @source = source
      end

      # @api public
      # @since 0.1.0
      alias_method :subresource_integrity_value, :sri

      # Returns the asset's full URL.
      #
      # @example Asset from local dev server
      #   asset.url # => "https://example.com/assets/app.js"
      #
      # @example Deployed asset with fingerprinted name
      #   asset.url # => "https://example.com/assets/app-28a6b886de2372ee3922fcaf3f78f2d8.js"
      #
      # @return [String]
      #
      # @api public
      # @since 0.1.0
      def url
        base_url.join(path)
      end

      # Returns the asset's full URL
      #
      # @return [String]
      #
      # @see #url
      #
      # @api public
      # @since 0.1.0
      def to_s
        url
      end
    end
  end
end