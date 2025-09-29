# frozen_string_literal: true

require "hanami/view/html"

module Hanami
  class Assets
    # Asset helpers for use in templates
    #
    # @api public
    # @since 0.1.0
    module Helpers
      # Generate a stylesheet link tag
      #
      # @param sources [Array<String>] one or more stylesheet sources
      # @param options [Hash] HTML attributes
      #
      # @return [String] HTML link tags
      #
      # @api public
      # @since 0.1.0
      def stylesheet_tag(*sources, **options)
        sources.map do |source|
          if external_source?(source)
            stylesheet_link_tag(source, **options)
          else
            begin
              asset = hanami_assets[source + ".css"]
              attrs = build_stylesheet_attributes(asset, **options)
              stylesheet_link_tag(asset.url, **attrs)
            rescue AssetMissingError
              stylesheet_link_tag("#{hanami_assets.config.path_prefix}/#{source}.css", **options)
            end
          end
        end.join("\n").html_safe
      end

      # Generate a javascript script tag
      #
      # @param sources [Array<String>] one or more javascript sources
      # @param options [Hash] HTML attributes
      #
      # @return [String] HTML script tags
      #
      # @api public
      # @since 0.1.0
      def javascript_tag(*sources, **options)
        sources.map do |source|
          if external_source?(source)
            javascript_include_tag(source, **options)
          else
            begin
              asset = hanami_assets[source + ".js"]
              attrs = build_javascript_attributes(asset, **options)
              javascript_include_tag(asset.url, **attrs)
            rescue AssetMissingError
              javascript_include_tag("#{hanami_assets.config.path_prefix}/#{source}.js", **options)
            end
          end
        end.join("\n").html_safe
      end

      # Generate an image tag
      #
      # @param source [String] image source
      # @param options [Hash] HTML attributes
      #
      # @return [String] HTML img tag
      #
      # @api public
      # @since 0.1.0
      def image_tag(source, **options)
        if external_source?(source)
          build_image_tag(source, **options).html_safe
        else
          begin
            # Try common image extensions
            %w[.png .jpg .jpeg .gif .svg].each do |ext|
              begin
                asset = hanami_assets[source + ext]
                return build_image_tag(asset.url, **options).html_safe
              rescue AssetMissingError
                next
              end
            end

            # Fallback to direct path
            build_image_tag("#{hanami_assets.config.path_prefix}/#{source}", **options).html_safe
          rescue AssetMissingError
            build_image_tag("#{hanami_assets.config.path_prefix}/#{source}", **options).html_safe
          end
        end
      end

      # Get the URL for an asset
      #
      # @param source [String] asset source
      #
      # @return [String] asset URL
      #
      # @api public
      # @since 0.1.0
      def asset_url(source)
        if external_source?(source)
          source
        else
          begin
            hanami_assets[source].url
          rescue AssetMissingError
            "#{hanami_assets.config.path_prefix}/#{source}"
          end
        end
      end

      # Get the path for an asset (without base URL)
      #
      # @param source [String] asset source
      #
      # @return [String] asset path
      #
      # @api public
      # @since 0.1.0
      def asset_path(source)
        if external_source?(source)
          source
        else
          begin
            hanami_assets[source].path
          rescue AssetMissingError
            "#{hanami_assets.config.path_prefix}/#{source}"
          end
        end
      end


      private

      def hanami_assets
        # This should be set by the framework integration
        @hanami_assets or raise "Hanami::Assets instance not configured"
      end

      def external_source?(source)
        source.start_with?('http://') || source.start_with?('https://') || source.start_with?('//')
      end

      def stylesheet_link_tag(href, **options)
        attrs = { href: href, type: "text/css", rel: "stylesheet" }.merge(options)
        "<link#{build_html_attributes(attrs)}>"
      end

      def javascript_include_tag(src, **options)
        attrs = { src: src, type: "text/javascript" }.merge(options)
        "<script#{build_html_attributes(attrs)}></script>"
      end

      def build_image_tag(src, **options)
        attrs = { src: src }.merge(options)
        "<img#{build_html_attributes(attrs)}>"
      end


      def build_stylesheet_attributes(asset, **options)
        attrs = options.dup

        if hanami_assets.subresource_integrity? && asset.sri && hanami_assets.crossorigin?(asset.url)
          attrs[:integrity] = asset.sri
          attrs[:crossorigin] = "anonymous" unless attrs.key?(:crossorigin)
        end

        attrs
      end

      def build_javascript_attributes(asset, **options)
        attrs = options.dup

        if hanami_assets.subresource_integrity? && asset.sri && hanami_assets.crossorigin?(asset.url)
          attrs[:integrity] = asset.sri
          attrs[:crossorigin] = "anonymous" unless attrs.key?(:crossorigin)
        end

        attrs
      end


      def build_html_attributes(attrs)
        attrs.map do |key, value|
          if value == true
            " #{key}"
          elsif value
            " #{key}=\"#{escape_html(value)}\""
          end
        end.join
      end

      def escape_html(string)
        string.to_s.gsub(/[&<>"]/, {
          "&" => "&amp;",
          "<" => "&lt;",
          ">" => "&gt;",
          '"' => "&quot;"
        })
      end

    end
  end
end