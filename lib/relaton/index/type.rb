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
      #
      def initialize(type, url = nil)
        @file_io = FileIO.new type.to_s.downcase, url
        @index = @file_io.read
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
        item = @index.find { |i| i[:id] == id }
        if item
          item[:file] = file
        else
          @index << { id: id, file: file }
        end
      end

      #
      # Search index for a given ID
      #
      # @param [Comparable] id ID to search for
      #
      # @return [Array<Hash>] search results
      #
      def search(id)
        @index.select do |i|
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
    end
  end
end
