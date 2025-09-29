# frozen_string_literal: true

require "uri"

module Hanami
  class Assets
    # Base URL for assets
    #
    # @api private
    # @since 0.1.0
    class BaseUrl
      # @api private
      # @since 0.1.0
      attr_reader :url

      # @api private
      # @since 0.1.0
      def initialize(url = "")
        @url = url.to_s
      end

      # Join the base URL with a path
      #
      # @param path [String] the path to join
      #
      # @return [String] the full URL
      #
      # @api private
      # @since 0.1.0
      def join(path)
        return path if url.empty?

        if url.end_with?("/")
          url + path.sub(%r{^/}, "")
        else
          url + path
        end
      end

      # Returns true if the given source is linked via Cross-Origin policy
      #
      # @param source [String] the source URL
      #
      # @return [Boolean]
      #
      # @api private
      # @since 0.1.0
      def crossorigin?(source)
        return false if url.empty?

        begin
          base_uri = URI.parse(url)
          source_uri = URI.parse(source)

          base_uri.host != source_uri.host || base_uri.port != source_uri.port || base_uri.scheme != source_uri.scheme
        rescue URI::InvalidURIError
          false
        end
      end
    end
  end
end