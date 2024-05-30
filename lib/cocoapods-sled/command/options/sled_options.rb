require 'cocoapods-sled/podfile/dsl_ext'
require 'cocoapods-sled/framework_cache'

module Pod
  class Command
    module Options
      module SledOptions

        module Options
          def options
            [
              ['--no-binary-pods=name', '禁用指定的 Pod 二进制缓存，多个 Pod 名称用","分隔, 优先级高于 --all-binary'],
              ['--all-binary', '强制使用二进制缓存，忽略 Podfile 中 `:binary` 设置'],
              ['--header-search-path', '生成 Header Search Path，一般用于打包机'],
              ['--project=name', '工程名称，用于生成framework缓存目录，区分多个工程的缓存'],
              ['--no-dev-pod', '关闭 Development Pods 二进制缓存，默认是开启的'],
              ['--force-sync-dev-pod', '强制缓存 Development Pods 编译结果，忽略本地修改检查，默认本地有修改时不缓存，一般用于打包机'],
              ['--inhibit-all-warnings', '强制关闭警告，忽略 Podfile 中的配置，一般用于打包机'],
              ['--cache-limit=num', '指定每个 Pod 缓存存储上限数量，小于 3 无效，一般用于打包机'],
              ['--dep-check=[single|all]', '检查依赖库版本是否发生变更，single：只检查直接依赖，all：检查全部依赖，一般用于打包机'],
              ['--check-xcode-version', '检查xcode版本，不同版本打包不复用，使用 xcodebuild -version 获取版本信息，一般用于打包机'],
              ['--configuration=[Debug|Release|自定义]', '编译配置用于生产缓存路径(Debug、Release、自定义)，不传则不区分共用，一般用于打包机']
            ].concat(super)
          end
        end

        def self.included(base)
          base.extend(Options)
        end

        def initialize(argv)
          Podfile::DSL.sled_disable_binary_pods = argv.option('no-binary-pods', '').split(',')
          count = argv.option('cache-limit', '').to_i
          if !count.nil? && count >= 3 
            FrameworkCache.sled_cache_limit = count
          end

          check_type = argv.option('dep-check', '').to_sym
          if VALID_DEPENDENCY_CHECK_TYPE.include? check_type
            Podfile::DSL.dependency_check_type = check_type
          end

          Podfile::DSL.sled_configuration = argv.option('configuration', DEFAULT_CONFIGURATION).to_s

          Podfile::DSL.sled_project_name = argv.option('project', '')
           
          Installer.sled_force_binary = argv.flag?('all-binary', false)
          if argv.flag?('header-search-path', false)
            Podfile::DSL.sled_enable_generate_header_search_paths = true
          end
          if argv.flag?('no-dev-pod', false)
            Podfile::DSL.sled_disable_binary_cache_for_dev_pod = true
          end
          if argv.flag?('force-sync-dev-pod', false)
            Installer.sled_force_rsync_local_pod = true
          end
          if argv.flag?('inhibit-all-warnings', false)
            Podfile::DSL.sled_inhibit_all_warnings = true
          end
          if argv.flag?('check-xcode-version', false)
            Podfile::DSL.sled_check_xcode_version = true
          end
          super
        end
      end
    end
  end
end