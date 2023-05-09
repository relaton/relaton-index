module Relaton
  module Index
    #
    # Relaton::Index::Type is a class for indexing Relaton files.
    #
    class Type
      #
      # Initialize a new Relaton::Index::Type object
      #
      # @param [String, Symbol] type type of index (ISO, IEC, etc.)
      # @param [String, nil] url external URL to index, used to fetch index for searching files
      # @param [String, nil] file output file name
      #
      def initialize(type, url = nil, file = nil)
        @file = file
        filename = file || Index.config.filename
        @file_io = FileIO.new type.to_s.downcase, url, filename
      end

      def index
        @index ||= @file_io.read
      end

      #
      # Check if index is actual. If url or file is given, check if it is equal to
      # index url or file.
      #
      # @param [Hash] **args arguments
      # @option args [String, nil] :url external URL to index, used to fetch index for searching files
      # @option args [String, nil] :file output file name
      #
      # @return [Boolean] true if index is actual, false otherwise
      #
      def actual?(**args)
        (!args.key?(:url) || args[:url] == @file_io.url) && (!args.key?(:file) || args[:file] == @file)
      end

      #
      # Add or update index item
      #
      # @param [String] id document ID
      # @param [String] file file name of the document
      #
      # @return [void]
      #
      def add_or_update(id, file)
        item = index.find { |i| i[:id] == id }
        if item
          item[:file] = file
        else
          index << { id: id, file: file }
        end
      end

      #
      # Search index for a given ID
      #
      # @param [Comparable] id ID to search for
      #
      # @return [Array<Hash>] search results
      #
      def search(id = nil)
        index.select do |i|
          block_given? ? yield(i) : i[:id].include?(id)
        end
      end

      #
      # Save index to storage
      #
      # @return [void]
      #
      def save
        @file_io.save @index
      end

      #
      # Remove index file from storage and clear index
      #
      # @return [void]
      #
      def remove
        @file_io.remove
        @index = nil
      end

      #
      # Remove all index items
      #
      # @return [void]
      #
      def remove_all
        @index = []
      end
    end
  end
end
