# frozen_string_literal: true

require "yaml"
require "zip"
require "relaton/logger"

require_relative "index/version"
require_relative "index/file_storage"
require_relative "index/config"
require_relative "index/util"
require_relative "index/pool"
require_relative "index/type"
require_relative "index/file_io"

module Relaton
  module Index
    class Error < StandardError; end

    class << self
      #
      # Find or create index
      #
      # @param [String] type index type (ISO, IEC, etc.)
      # @param [String, nil] url external URL to index, used to fetch index for searching files
      # @param [String, nil] file output file name, default is config.filename
      # @param [Array<Symbol>, nil] id_keys keys to check if index is correct
      #
      # @return [Relaton::Index::Type] typed index
      #
      def find_or_create(type, url: nil, file: nil, id_keys: nil)
        pool.type(type, url: url, file: file, id_keys: id_keys)
      end

      def close(type)
        pool.remove type
      end

      #
      # Create new index pool object or return existing
      #
      # @return [Relaton::Index::Pool] index pool
      #
      def pool
        @pool ||= Pool.new
      end

      #
      # Create new config object or return existing
      #
      # @return [Relaton::Index::Config] config object
      #
      def config
        @config ||= Config.new
      end

      #
      # Configure Relaton::Index
      #
      # @return [void]
      #
      def configure
        yield config
      end
    end
  end
end
