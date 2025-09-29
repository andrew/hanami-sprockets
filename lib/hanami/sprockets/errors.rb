# frozen_string_literal: true

module Hanami
  class Assets
    # Base error for Hanami::Assets
    #
    # @since 0.1.0
    class Error < StandardError
    end

    # Error raised when a requested asset cannot be found
    #
    # @since 0.1.0
    class AssetMissingError < Error
      def initialize(path)
        super("Missing asset: #{path}")
      end
    end

    # Error raised when the asset manifest cannot be found
    #
    # @since 0.1.0
    class ManifestMissingError < Error
      def initialize(path)
        super("Missing manifest: #{path}")
      end
    end
  end
end