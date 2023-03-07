module Relaton
  module Index
    #
    # Configuration class for Relaton::Index
    #
    class Config
      attr_reader :storage, :storage_dir

      #
      # Set default values
      #
      def initialize
        @storage = FileStorage
        @storage_dir = Dir.home
      end

      #
      # Set storage
      #
      # @param [#ctime, #read, #write] storage storage object
      #
      # @return [void]
      #
      def storage=(storage)
        @storage = storage
      end

      #
      # Set storage directory
      #
      # @param [String] dir storage directory
      #
      # @return [void]
      #
      def storage_dir=(dir)
        @storage_dir = dir
      end
    end
  end
end
