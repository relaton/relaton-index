module Relaton
  module Index
    #
    # File IO class is used to read and write index files.
    # In searh mode url is used to fetch index from external repository and save it to storage.
    # In index mode url should be nil.
    #
    class FileIO
      #
      # Initialize FileIO
      #
      # @param [String] dir local directory in ~/.relaton to store index
      # @param [String, nil] url git repository URL to fetch index from (if not exists, or older than 24 hours)
      #   or nil if index is used to index files
      #
      def initialize(dir, url)
        @dir = dir
        @url = url
      end

      #
      # Read index from storage or fetch from external repository
      #
      # @return [Array<Hash>] index
      #
      def read
        if @url
          @file ||= File.join(Index.config.storage_dir, ".relaton", @dir, "index.yaml")
          check_file || fetch_and_save
        else
          @file ||= "index.yaml"
          read_file
        end
      end

      #
      # Check if index file exists and is not older than 24 hours
      #
      # @return [Array<Hash>, nil] index or nil
      #
      def check_file
        ctime = Index.config.storage.ctime(@file)
        return unless ctime && ctime > Time.now - 86400

        read_file
      end

      #
      # Read index from storage
      #
      # @return [Array<Hash>] index
      #
      def read_file
        yaml = Index.config.storage.read(@file)
        return [] unless yaml

        YAML.safe_load yaml, permitted_classes: [Symbol]
      end

      #
      # Fetch index from external repository and save it to storage
      #
      # @return [Array<Hash>] index
      #
      def fetch_and_save
        resp = URI(@url).open
        zip = Zip::InputStream.new resp
        entry = zip.get_next_entry
        index = YAML.safe_load(entry.get_input_stream.read, permitted_classes: [Symbol])
        save index
        index
      end

      #
      # Save index to storage
      #
      # @param [Array<Hash>] index <description>
      #
      # @return [void]
      #
      def save(index)
        Index.config.storage.write @file, index.to_yaml
      end
    end
  end
end
