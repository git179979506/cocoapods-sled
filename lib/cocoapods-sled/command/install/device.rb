module Pod
  class Command
    class Install < Command
      class Device < Install
        require 'cocoapods-sled/installer_options'
        require 'cocoapods-sled/command/options/sled_options'

        include SledOptions

        self.summary = '查找真机二进制缓存'

        self.description = <<-DESC
          #{self.summary}，缓存目录: `#{Config.instance.cache_root + 'Frameworks'}`.
        DESC

        def initialize(argv)
          super
        end

        def validate!
          super
        end

        def run
          Pod::Installer.sled_reuse_type = :device
          super
        end
      end
    end
  end
end