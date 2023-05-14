module Relaton
  module Index
    #
    # File IO class is used to read and write index files.
    # In searh mode url is used to fetch index from external repository and save it to storage.
    # In index mode url should be nil.
    #
    class FileIO
      attr_reader :url

      #
      # Initialize FileIO
      #
      # @param [String] dir local directory in ~/.relaton to store index
      # @param [String, Boolean, nil] url git repository URL to fetch index from
      #   (if not exists, or older than 24 hours) or nil if index is used to
      #   index files
      #
      def initialize(dir, url, filename)
        @dir = dir
        @url = url
        @filename = filename
      end

      #
      # If url is String, check if index file exists and is not older than 24
      #   hours. If not, fetch index from external repository and save it to
      #   storage.
      # If url is true, remove index from storage.
      # If url is nil, read index from file.
      #
      # @return [Array<Hash>] index
      #
      def read
        case url
        when String
          check_file || fetch_and_save
        else
          read_file
        end
      end

      def file
        @file ||= url ? path_to_local_file : @filename
      end

      #
      # Create path to local file
      #
      # @return [<Type>] <description>
      #
      def path_to_local_file
        File.join(Index.config.storage_dir, ".relaton", @dir, @filename)
      end

      #
      # Check if index file exists and is not older than 24 hours
      #
      # @return [Array<Hash>, nil] index or nil
      #
      def check_file
        ctime = Index.config.storage.ctime(file)
        return unless ctime && ctime > Time.now - 86400

        read_file
      end

      #
      # Read index from storage
      #
      # @return [Array<Hash>] index
      #
      def read_file
        yaml = Index.config.storage.read(file)
        return [] unless yaml

        YAML.safe_load yaml, permitted_classes: [Symbol]
      end

      #
      # Fetch index from external repository and save it to storage
      #
      # @return [Array<Hash>] index
      #
      def fetch_and_save
        resp = URI(url).open
        zip = Zip::InputStream.new resp
        entry = zip.get_next_entry
        index = YAML.safe_load(entry.get_input_stream.read, permitted_classes: [Symbol])
        save index
        index
      end

      #
      # Save index to storage
      #
      # @param [Array<Hash>] index index to save
      #
      # @return [void]
      #
      def save(index)
        Index.config.storage.write file, index.to_yaml
      end

      #
      # Remove index file from storage
      #
      # @return [Array]
      #
      def remove
        Index.config.storage.remove file
        []
      end
    end
  end
end
