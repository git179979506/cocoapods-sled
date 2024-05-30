require_relative '../podfile/target_definition_ext'
require 'digest'

module Pod
  class PodTarget < Target

    def sled_enable_generate_header_search_paths?
      return @sled_enable_generate_header_search_paths if defined? @sled_enable_generate_header_search_paths
      whitelists = target_definitions.map do |target_definition|
        target_definition.sled_option_header_search_paths.value_for_pod(root_spec.name)
      end.flatten.uniq.reject { |element| element == nil }

      if whitelists.empty?
        @sled_enable_generate_header_search_paths = Podfile::DSL.sled_enable_generate_header_search_paths
      elsif whitelists.count == 1
        @sled_enable_generate_header_search_paths = !!whitelists.first
      else
        value = whitelists.first
        tmp_td = target_definitions
          .detect { |obj| obj.sled_option_header_search_paths.value_for_pod(root_spec.name).first == value }
        target_name = tmp_td == nil ? "unknown" : tmp_td.name
        UI.warn "The pod `#{pod_name}` is linked to different targets " \
          "(#{target_definitions.map { |td| "`#{td.name}`" }.to_sentence}), which contain different " \
          'settings to hsp. CocoaPods does not currently ' \
          'support different settings and will fall back to your preference ' \
          "set in the `#{target_name}` target definition" \
          " :hsp => #{value}."
        @sled_enable_generate_header_search_paths = !!value
      end
      @sled_enable_generate_header_search_paths
    end

    def seld_ignore_binary?
      sled_option_binary_value == :ignore
    end

    def sled_enable_binary?
      sled_option_binary_value == true
    end

    def sled_option_binary_value
      return @sled_option_binary_value if defined? @sled_option_binary_value
      whitelists = target_definitions.map do |target_definition|
        target_definition.sled_option_binary.value_for_pod(root_spec.name)
      end.flatten.uniq.reject { |element| element == nil }

      if whitelists.empty?
        @sled_option_binary_value = Podfile::DSL.sled_enable_binary_cache
      elsif whitelists.count == 1
        @sled_option_binary_value = whitelists.first
      else
        value = whitelists.first
        tmp_td = target_definitions
          .detect { |obj| obj.sled_option_binary.value_for_pod(root_spec.name).first == value }
        target_name = tmp_td == nil ? "unknown" : tmp_td.name
        UI.warn "The pod `#{pod_name}` is linked to different targets " \
          "(#{target_definitions.map { |td| "`#{td.name}`" }.to_sentence}), which contain different " \
          "settings to binary. CocoaPods does not currently " \
          'support different settings and will fall back to your preference ' \
          "set in the `#{target_name}` target definition" \
          " :binary => #{value}."
        @sled_option_binary_value = value
      end
      @sled_option_binary_value
    end

    def sled_predownloaded?
      sandbox.predownloaded_pods.include?(root_spec.name)
    end

    def sled_local?
      sandbox.local?(root_spec.name)
    end

    def sled_released?
      !sled_local? && !sled_predownloaded? && sandbox.specification(root_spec.name) != root_spec
    end

    def sled_local_pod_paths
      paths = []
      paths =file_accessors.map(&:path_list).map(&:root).uniq if sled_local?
      paths
    end

    def sled_slug_current 
      case Podfile::DSL.dependency_check_type
      when :single
        sled_plain_slug
      when :all
        sled_complex_slug
      else
        sled_slug
      end
    end

    # 不检查依赖
    def sled_slug
      @sled_slug ||= sled_download_request.slug
      @sled_slug
    end

    # 检查直接依赖
    def sled_plain_slug
      if dependent_targets.empty?
        @sled_plain_slug ||= sled_slug
      else 
        if @sled_plain_slug.nil?
          tmp_slug = dependent_targets.map { |t| t.sled_slug }.join("-")
          @sled_plain_slug = "#{sled_slug}-#{Digest::MD5.hexdigest(tmp_slug)}"
        end
      end
      @sled_plain_slug
    end

    # 检查全部依赖
    def sled_complex_slug
      if dependent_targets.empty?
        @sled_complex_slug ||= sled_slug
      else 
        if @sled_complex_slug.nil?
          tmp_slug = dependent_targets.map { |t| t.sled_complex_slug }.join("-")
          @sled_complex_slug = "#{sled_slug}-#{Digest::MD5.hexdigest(tmp_slug)}"
        end
      end
      @sled_complex_slug
    end

    def sled_download_request
      if sled_local?
        commit_id = file_accessors
          .map(&:path_list)
          .map(&:root).uniq
          .map do |path|
              `git -C #{path} log -1 --pretty=format:%H #{path} 2>/dev/null`
          end
          .join("")

        if commit_id.empty?
          request = nil
        else 
          params = { :commit => commit_id }
          request = Downloader::Request.new(
              :name => root_spec.name,
              :params => params,
          )
        end
      elsif sandbox.checkout_sources && sandbox.checkout_sources.keys.include?(root_spec.name)
          params = sandbox.checkout_sources[root_spec.name]

          request = Downloader::Request.new(
              :name => root_spec.name,
              :params => params,
          )
      else
          request = Downloader::Request.new(
              :spec => root_spec,
              :released => sled_released?,
          )
      end

      request
    end
  end
end