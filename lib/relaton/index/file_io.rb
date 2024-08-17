module Relaton
  module Index
    #
    # File IO class is used to read and write index files.
    # In searh mode url is used to fetch index from external repository and save it to storage.
    # In index mode url should be nil.
    #
    class FileIO
      attr_reader :url, :pubid_class

      #
      # Initialize FileIO
      #
      # @param [String] dir falvor specific local directory in ~/.relaton to store index
      # @param [String, Boolean, nil] url
      #   if String then the URL is used to fetch an index from a Git repository
      #     and save it to the storage (if not exists, or older than 24 hours)
      #   if true then the index is read from the storage (used to remove index file)
      #   if nil then the fiename is used to read and write file (used to create indes in GH actions)
      # @param [Pubid::Core::Identifier::Base] pubid class for deserialization
      #
      def initialize(dir, url, filename, id_keys, pubid_class = nil)
        @dir = dir
        @url = url
        @filename = filename
        @id_keys = id_keys || []
        @pubid_class = pubid_class
      end

      #
      # If url is String, check if index file exists and is not older than 24
      #   hours. If not, fetch index from external repository and save it to
      #   storage.
      # If url is true, read index from path to local file.
      # If url is nil, read index from filename.
      #
      # @return [Array<Hash>] index
      #
      def read
        case url
        when String
          check_file || fetch_and_save
        else
          read_file || []
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
      # Check if index has correct format
      #
      # @param [Array<Hash>] index index to check
      #
      # @return [Boolean] <description>
      #
      def check_format(index)
        check_basic_format(index) && check_id_format(index)
      end

      def check_basic_format(index)
        return false unless index.is_a? Array

        keys = %i[file id]
        index.all? { |item| item.respond_to?(:keys) && item.keys.sort == keys }
      end

      def check_id_format(index)
        return true if @id_keys.empty?

        keys = index.each_with_object(Set.new) do |item, acc|
          acc.merge item[:id].keys if item[:id].is_a?(Hash)
        end
        keys.none? { |k| !@id_keys.include? k }
      end

      #
      # Read index from storage
      #
      # @return [Array<Hash>] index
      #
      def read_file
        yaml = Index.config.storage.read(file)
        return unless yaml

        load_index(yaml) || []
      end

      def deserialize_pubid(index)
        return index unless @pubid_class

        index.map { |r| { id: @pubid_class.create(**r[:id]), file: r[:file] } }
      end

      def warn_local_index_error(reason)
        Util.info "#{reason} file `#{file}`", progname
        if url.is_a? String
          Util.info "Considering `#{file}` file corrupt, re-downloading from `#{url}`", progname
        else
          Util.info "Considering `#{file}` file corrupt, removing it.", progname
          remove
        end
      end

      def progname
        @progname ||= "relaton-#{@dir}"
      end

      def load_index(yaml, save = false)
        index = YAML.safe_load(yaml, permitted_classes: [Symbol])
        save index if save
        return deserialize_pubid(index) if check_format index

        if save
          warn_remote_index_error "Wrong structure of"
        else
          warn_local_index_error "Wrong structure of"
        end
      rescue Psych::SyntaxError
        if save
          warn_remote_index_error "YAML parsing error when reading"
        else
          warn_local_index_error "YAML parsing error when reading"
        end
      end
      #
      # Fetch index from external repository and save it to storage
      #
      # @return [Array<Hash>] index
      #
      def fetch_and_save
        resp = StringIO.new(URI(url).read)
        zip = Zip::InputStream.new resp
        entry = zip.get_next_entry
        yaml = entry.get_input_stream.read
        Util.info "Downloaded index from `#{url}`", progname
        load_index(yaml, save = true)
      end

      def warn_remote_index_error(reason)
        Util.info "#{reason} newly downloaded file `#{file}` at `#{url}`, " \
             "the remote index seems to be invalid. Please report this " \
             "issue at https://github.com/relaton/relaton-cli.", progname
      end

      #
      # Save index to storage
      #
      # @param [Array<Hash>] index index to save
      #
      # @return [void]
      #
      def save(index)
        Index.config.storage.write file,
          index.map { |item| item.transform_values { |value| value.is_a?(Pubid::Core::Identifier::Base) ? value.to_h : value } }.to_yaml
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
