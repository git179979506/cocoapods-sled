require_relative '../tool'

module Pod
    class Sandbox
        class PathList
            attr_accessor :sled_framework_cache_roots

            old_read_file_system = instance_method(:read_file_system)
            define_method(:read_file_system) do 
                old_read_file_system.bind(self).()

                return if sled_framework_cache_roots.nil? || sled_framework_cache_roots.empty?
                sled_framework_cache_roots.each do |root|
                  sled_read_framework_file_system(root) 
                end
            end

            def add_cache_root(root)
              @sled_framework_cache_roots ||= [] 
              @sled_framework_cache_roots << root unless @sled_framework_cache_roots.include?(root)
            end

            def sled_read_framework_file_system(path)
                unless path.exist?
                  # raise Informative, "Attempt to read non existent folder `#{root}`."
                  Pod::UI.puts "⚠️⚠️⚠️ Attempt to read non existent folder `#{path}`."
                  return
                end
        
                prefix = path.relative_path_from(root)
        
                dirs = []
                files = []
                root_length = path.cleanpath.to_s.length + File::SEPARATOR.length
                escaped_root = escape_path_for_glob(path)
                Dir.glob(escaped_root + '**/*', File::FNM_DOTMATCH).each do |f|
                  directory = File.directory?(f)
                  # Ignore `.` and `..` directories
                  next if directory && f =~ /\.\.?$/
        
                  f = f.slice(root_length, f.length - root_length)
                  next if f.nil?
        
                  (directory ? dirs : files) << (prefix + f).to_s
                end
        
                dirs.sort_by!(&:upcase)
                files.sort_by!(&:upcase)
        
                @dirs = @dirs + dirs
                @files = @files + files
              end
        end
    end
end