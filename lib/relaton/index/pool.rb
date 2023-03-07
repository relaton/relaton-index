module Relaton
  module Index
    #
    # Pool of indexes
    #
    class Pool
      def initialize
        @pool = {}
      end

      #
      # Return index by type, create if not exists
      #
      # @param [String] type <description>
      # @param [String, nil] url external URL to index, used to fetch index for searching files
      #
      # @return [Relaton::Index::Type] typed index
      #
      def type(type, url)
        @pool[type.upcase.to_sym] ||= Type.new(type, url)
      end

      #
      # Remove index by type from pool
      #
      # @param [String] type index type
      #
      # @return [void]
      #
      def remove(type)
        @pool.delete type.upcase.to_sym
      end
    end
  end
end
