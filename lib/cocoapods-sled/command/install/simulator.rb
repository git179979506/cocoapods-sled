module Pod
  class Command
    class Install < Command
      class Simulator < Install
        require 'cocoapods-sled/installer_options'

        require 'cocoapods-sled/command/options/sled_options'

        include SledOptions

        self.summary = '查找模拟器二进制缓存'

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
          Pod::Installer.sled_reuse_type = :simulator
          super
        end
      end
    end
  end
end