require 'fileutils'
require 'tmpdir'

module Pod
  # The class responsible for managing Pod downloads, transparently caching
  # them in a cache directory.
  #
  class FrameworkCache

    class_attr_accessor :sled_cache_limit
    self.sled_cache_limit = 4

    # @return [Pathname] The root directory where this cache store its
    #         downloads.
    #
    attr_reader :root

    # Initialize a new instance
    #
    # @param  [Pathname,String] root
    #         see {#root}
    #
    def initialize()
      @root = Pathname(Config.instance.cache_root + 'Frameworks')
    end

    def path_for_framework(slug)
      root + slug
    end

    def remove_size_exceeded_values(request)
      pod_cache_dir = root + request.sled_cache_subpath
      return unless pod_cache_dir.directory?

      array = pod_cache_dir.children.select { |pn| pn.directory? }.sort { |a, b| a.mtime <=> b.mtime }
      limit = FrameworkCache.sled_cache_limit
      if array.count > limit # 数量支持配置
        array.take(array.count - limit).each { |pn| `rm -dr #{pn.to_s}` } # 权限问题
      end
    end

    # @param  [Request] request
    #         the request to be downloaded.
    #
    # @return [Response] The download response for the given `request` that
    #         was found in the download cache.
    #
    def cached_pod(request)
      cached_spec = cached_spec(request)
      path = path_for_pod(request)

      return unless cached_spec && path.directory?
      spec = request.spec || cached_spec
      Response.new(path, spec, request.params)
    end

    # Copies the `source` directory to `destination`, cleaning the directory
    # of any files unused by `spec`.
    #
    # @param  [Pathname] source
    #
    # @param  [Pathname] destination
    #
    # @param  [Specification] spec
    #
    # @return [Void]
    #
    def copy_and_clean(source, destination, spec)
      specs_by_platform = group_subspecs_by_platform(spec)
      destination.parent.mkpath
      FileUtils.rm_rf(destination)
      FileUtils.cp_r(source, destination)
      Pod::Installer::PodSourcePreparer.new(spec, destination).prepare!
      Sandbox::PodDirCleaner.new(destination, specs_by_platform).clean!
    end

    def group_subspecs_by_platform(spec)
      specs_by_platform = {}
      [spec, *spec.recursive_subspecs].each do |ss|
        ss.available_platforms.each do |platform|
          specs_by_platform[platform] ||= []
          specs_by_platform[platform] << ss
        end
      end
      specs_by_platform
    end

    # Writes the given `spec` to the given `path`.
    #
    # @param  [Specification] spec
    #         the specification to be written.
    #
    # @param  [Pathname] path
    #         the path the specification is to be written to.
    #
    # @return [Void]
    #
    def write_spec(spec, path)
      path.dirname.mkpath
      path.open('w') { |f| f.write spec.to_pretty_json }
    end

    # @return [Hash<String, Hash<Symbol, String>>]
    #         A hash whose keys are the pod name
    #         And values are a hash with the following keys:
    #         :spec_file : path to the spec file
    #         :name      : name of the pod
    #         :version   : pod version
    #         :release   : boolean to tell if that's a release pod
    #         :slug      : the slug path where the pod cache is located
    #
    def cache_descriptors_per_pod
      specs_dir = root + 'Specs'
      release_specs_dir = specs_dir + 'Release'
      return {} unless specs_dir.exist?

      spec_paths = specs_dir.find.select { |f| f.fnmatch('*.podspec.json') }
      spec_paths.reduce({}) do |hash, spec_path|
        spec = Specification.from_file(spec_path)
        hash[spec.name] ||= []
        is_release = spec_path.to_s.start_with?(release_specs_dir.to_s)
        request = Downloader::Request.new(:spec => spec, :released => is_release)
        hash[spec.name] << {
          :spec_file => spec_path,
          :name => spec.name,
          :version => spec.version,
          :release => is_release,
          :slug => root + request.slug,
        }
        hash
      end
    end
  end

  module Downloader
    class Request
      def sled_cache_subpath(name: self.name)

        if released_pod?
          "Release/#{name}"
        else
          "External/#{name}"
        end
      end
    end
  end
end