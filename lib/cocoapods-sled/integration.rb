require_relative 'framework_cache'
require_relative 'tool'
require_relative 'sandbox/path_list_ext'
require_relative 'podfile/dsl_ext'
require_relative 'target/pod_target_ext'

module Pod
    class Target

        def sled_sepc_full_name 
            name = specs.sort_by(&:name)
                .map { |spec| spec.name.sub("#{root_spec.name}/", "").gsub("/", "-") }
                .join("-") # 区分不同subspec打包的framework
            name = root_spec.name + "-" + name if !name.include?(root_spec.name)
            # File name too long
            if name.length > 50 
                name = Digest::MD5.hexdigest(name)
            end
            name
        end 
        
        # 如果 Podfile 中重写了 build_as_static_framework? build_as_dynamic_framework?，但是没有修改 @build_type
        # verify_no_static_framework_transitive_dependencies 执行时，需要编译的pod库都按照修改前的build_type检查
        # 导致判断有问题报错：动态库不能依赖静态库
        # The 'Pods-xxx' target has transitive dependencies that include statically linked binaries: 
        def sled_adjust_build_type
            if build_as_static_framework?
                @build_type = BuildType.static_framework
            elsif build_as_dynamic_framework?
                @build_type = BuildType.dynamic_framework
            end
        end

        def sled_build_type_name
            "#{build_type.linkage}_#{build_type.packaging}"
        end

        def sled_framework_cache_subpath(reuse_type_name)
            "#{sled_build_type_name}/#{sled_sepc_full_name}/#{reuse_type_name}"
        end
    end
end

module Pod
    class Installer
        require 'cocoapods-sled/installer_options'

        SLED_VALID_PLATFORMS = Platform.all.freeze.map { |v| v.name.to_s }

        def f_cache
            @f_cache ||= FrameworkCache.new
        end

        old_install_pod_sources = instance_method(:download_dependencies)
        define_method(:download_dependencies) do 
            old_install_pod_sources.bind(self).()

            # Installer.sled_reuse_type = :device
            return unless Installer.sled_should_resure?

            UI.section "查找#{Installer.sled_reuse_type_desc} Sled 缓存" do
                sled_reuse_action
            end
        end

        def sled_reuse_action
            cache = []

            sled_totalTargets = []
            @sled_hits = []
            @sled_miss = []
            disable_binary_pod_targets = []

            pod_targets.each do |target|
                # 修正build_type
                # target.sled_adjust_build_type

                disable_binary_pod_targets << target.name if Podfile::DSL.sled_disable_binary_pods.include?(target.root_spec.name)
                next if Podfile::DSL.sled_disable_binary_pods.include?(target.root_spec.name)

                disable_binary_pod_targets << target.name if target.seld_ignore_binary?
                next if target.seld_ignore_binary?

                disable_binary_pod_targets << target.name unless Pod::Installer.sled_force_binary || target.sled_enable_binary?
                next unless Pod::Installer.sled_force_binary || target.sled_enable_binary?

                root_spec = target.root_spec


                sled_totalTargets << target.name 
                
                if target.sled_local?
                    return if Podfile::DSL.sled_disable_binary_cache_for_dev_pod
                    sled_modify_pod_target(target)
                else
                    sled_modify_pod_target(target)
                end
            end
            
            UI.puts " -> pod targets数量: #{pod_targets.count}".yellow
            UI.puts " -> binary disabled数量: #{disable_binary_pod_targets.count}".yellow
            disable_binary_pod_targets_text = disable_binary_pod_targets.join(", ")
            UI.puts "    #{disable_binary_pod_targets_text}" unless disable_binary_pod_targets_text.empty?
            UI.puts " -> 处理targets数量: #{sled_totalTargets.count}".yellow
            UI.puts " -> 命中数量: #{@sled_hits.count}".yellow
            UI.message "    #{@sled_hits.join(", ")}"
            UI.puts " -> 未命中数量: #{@sled_miss.count}".yellow
            sled_miss_text = @sled_miss.join(", ")
            UI.puts "    #{sled_miss_text}" unless sled_miss_text.empty?
        end

        def xcode_version
            @xcode_version ||= `xcodebuild -version | grep "Build version" | awk '{print $NF}' | head -1`.strip
        end

        def sled_modify_pod_target(target)
            request = target.sled_download_request
            return if request.nil?

            root_spec = target.root_spec

            slug = target.sled_slug_current
            if Podfile::DSL.sled_check_xcode_version
                slug = "#{slug}-#{xcode_version}"
            end
            unless Podfile::DSL.sled_project_name.empty?
                slug = "#{slug}-#{Podfile::DSL.sled_project_name}"
            end

            path = f_cache.path_for_framework(slug)
            
            pod_root = sandbox.pod_dir(root_spec.name)

            framework_dir_path = path + target.sled_framework_cache_subpath(Installer.sled_reuse_type_name)
            framework_file_path = framework_dir_path + target.product_name  
        
            if framework_file_path.directory?
                path.utime(Time.now, Time.now)

                @sled_hits << target.name

                # 1.12.x 相同 pod_root 重用了 path_list，这里会导致同目录下的podspec只能找到一个二进制
                target.file_accessors.map(&:path_list).each do |value|
                    value.add_cache_root(framework_dir_path)
                end

                framework_dir_relative_path = framework_dir_path.relative_path_from(pod_root)
                framework_file_relative_path = framework_file_path.relative_path_from(pod_root)

                target.specs.each do |spec|

                    sled_empty_source_files(spec)
                    sled_add_vendered_framework(spec, framework_file_relative_path.to_s)
                    sled_replace_resource_bundles(spec, framework_dir_relative_path.to_s)
                    sled_add_header_search_paths(spec, target, framework_file_path.to_s)
                end
            else
                @sled_miss << target.name
                sled_add_script_phases(target, path)
            end

            f_cache.remove_size_exceeded_values(request)
        end

        def sled_add_header_search_paths(spec, pod_target, framework_file_path)
            return unless pod_target.sled_enable_generate_header_search_paths?

            spec.attributes_hash["user_target_xcconfig"] ||= {}
            spec.attributes_hash["user_target_xcconfig"]["HEADER_SEARCH_PATHS"] = "#{framework_file_path}/Headers/"
            # "${PODS_ROOT}/#{target.copy_resources_script_path_for_spec(spec).relative_path_from(target.sandbox.root)}"
        end

        def sled_replace_resource_bundles(spec, framework_dir_path)
            if spec.attributes_hash["resource_bundles"]
                bundle_names = spec.attributes_hash["resource_bundles"].keys
                spec.attributes_hash["resource_bundles"] = nil 

                spec.attributes_hash["resources"] = Array(spec.attributes_hash["resources"])
                spec.attributes_hash["resources"] += bundle_names.map{ |name| "#{framework_dir_path}/#{name}.bundle" }
            end
        end
        
        # TODO: 待完善 参考 add_vendered_framework
        def sled_add_vendered_framework(spec, framework_file_path)

            spec.attributes_hash["vendored_frameworks"] = Array(spec.attributes_hash["vendored_frameworks"])
            spec.attributes_hash["vendored_frameworks"] += [framework_file_path]

            # spec.attributes_hash["source_files"] = framework_file_path + '/Headers/*.h'
            # spec.attributes_hash["public_header_files"] = framework_file_path + '/Headers/*.h'
            spec.attributes_hash["subspecs"] = nil
        end

        # source_files 置空
        def sled_empty_source_files(spec)
            spec.attributes_hash["source_files"] = []
            spec.attributes_hash["public_header_files"] = []
            # VALID_PLATFORMS = Platform.all.freeze
            SLED_VALID_PLATFORMS.each do |plat|
                if spec.attributes_hash[plat] != nil
                    spec.attributes_hash[plat]["source_files"] = []
                    spec.attributes_hash[plat]["public_header_files"] = []
                end
            end
        end

        def sled_add_script_phases(pod_target, chche_dir)

            rsync_func = ""

            # Local Pod不强制同步时，检查本地代码变更
            if pod_target.sled_local? && !Installer.sled_force_rsync_local_pod
                pod_target.sled_local_pod_paths.each do |path|
                    rsync_func << <<-SH.strip_heredoc
                    status=`git -C #{path} status -s #{path}`
                    
                    if [[ $status != "" ]]; then
                        echo "#{pod_target.name} 有变更，不同步编译结果"
                        echo $status
                        exit 0
                    fi

                    SH
                end
            end

            rsync_func << "#{Pod::Generator::ScriptPhaseConstants::RSYNC_PROTECT_TMP_FILES}"
            rsync_func << <<-SH.strip_heredoc

                framework_cache_path="#{chche_dir}/#{pod_target.sled_framework_cache_subpath("${CONFIGURATION}${EFFECTIVE_PLATFORM_NAME}")}"
                common_cache_path="#{chche_dir}/#{pod_target.sled_framework_cache_subpath("#{DEFAULT_CONFIGURATION}${EFFECTIVE_PLATFORM_NAME}")}"

                echo "mkdir -p ${framework_cache_path}" || true
                mkdir -p ${framework_cache_path}

                exec_rsync() {
                    echo "rsync -rLptgoDv --chmod=a=rwx "${RSYNC_PROTECT_TMP_FILES[@]}" ${CONFIGURATION_BUILD_DIR}/ ${framework_cache_path} &"

                    # TARGET_BUILD_DIR 在打包机上有问题，包含所有Framework，使用CONFIGURATION_BUILD_DIR
                    rsync -rLptgoDv --chmod=a=rwx "${RSYNC_PROTECT_TMP_FILES[@]}" "${CONFIGURATION_BUILD_DIR}/" "${framework_cache_path}" >/dev/null 2>>"#{chche_dir}/error.log"

                    ln -sfn "${framework_cache_path}" "${common_cache_path}"
                }

                (exec_rsync) &
            SH

            spec = pod_target.specs.first
            value = Array(spec.attributes_hash['script_phases'] || spec.attributes_hash['script_phase'])
            value << {
                :name => "Rsync Framework And Bundle To Sled Cache",
                :script => rsync_func
            }
            spec.attributes_hash["script_phases"] = value
        end
    end
end