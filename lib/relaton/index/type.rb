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
      # @param [Pubid::Core::Identifier::Base] pubid class for deserialization
      #
      def initialize(type, url = nil, file = nil, id_keys = nil, pubid_class = nil)
        @file = file
        filename = file || Index.config.filename
        @file_io = FileIO.new type.to_s.downcase, url, filename, id_keys, pubid_class
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
      # @param [Pubid::Core::Identifier::Base] id document ID
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
      # @param [String, Pubid::Core::Identifier::Base] id ID to search for
      #
      # @return [Array<Hash>] search results
      #
      def search(id = nil)
        index.select do |i|
          if block_given?
            yield(i)
          else
            if i[:id].is_a?(String)
              id.is_a?(String) ? i[:id].include?(id) : i[:id].include?(id.to_s)
            else
              id.is_a?(String) ? i[:id].to_s.include?(id) : i[:id] == id
            end
          end
        end
      end

      #
      # Save index to storage
      #
      # @return [void]
      #
      def save
        @file_io.save(@index || [])
      end

      #
      # Remove index file from storage and clear index
      #
      # @return [void]
      #
      def remove_file
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
