require_relative '../tool'

VALID_DEPENDENCY_CHECK_TYPE = %i(default single all).freeze
DEFAULT_CONFIGURATION = "Sled-Common"

module Pod
    class Podfile
        module DSL

            # def sled_enable_binary_cache!
            #     DSL.sled_enable_binary_cache = true
            # end

            def sled_disable_binary_cache_for_dev_pod!
                DSL.sled_disable_binary_cache_for_dev_pod = true
            end

            def sled_enable_generate_header_search_paths!
                DSL.sled_enable_generate_header_search_paths = true
            end

            def sled_disable_binary_pods(*names)
                DSL.sled_disable_binary_pods ||= []
                DSL.sled_disable_binary_pods.concat(names)
            end

            def sled_enable_binary_pods(*names)
                DSL.sled_enable_binary_pods ||= []
                DSL.sled_enable_binary_pods.concat(names)
            end

            private
            # 开启二进制缓存(默认开启，暂时不支持修改)
            class_attr_accessor :sled_enable_binary_cache
            self.sled_enable_binary_cache = true

            # 禁用 Development pods 二进制缓存
            class_attr_accessor :sled_disable_binary_cache_for_dev_pod
            self.sled_disable_binary_cache_for_dev_pod = false

            # 生成 HEADER_SEARCH_PATHS
            class_attr_accessor :sled_enable_generate_header_search_paths
            self.sled_enable_generate_header_search_paths = false

            class_attr_accessor :sled_inhibit_all_warnings
            self.sled_inhibit_all_warnings = false

            class_attr_accessor :sled_disable_binary_pods
            self.sled_disable_binary_pods = []

            class_attr_accessor :sled_enable_binary_pods
            self.sled_enable_binary_pods = []

            class_attr_accessor :dependency_check_type
            self.dependency_check_type = :default

            # 检查 xcode 版本，使用 xcodebuild -version 获取版本信息 Build version
            class_attr_accessor :sled_check_xcode_version
            self.sled_check_xcode_version = false

            # 工程名称，用于生成缓存目录，区分多个工程的缓存
            class_attr_accessor :sled_project_name
            self.sled_project_name = ''

            # 编译配置，用于生成缓存目录，默认不区分不同的编译配置(Debug | Release | 自定义)
            class_attr_accessor :sled_configuration
            self.sled_configuration = DEFAULT_CONFIGURATION
        end
    end
end
