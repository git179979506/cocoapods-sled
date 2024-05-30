module Pod
  class Podfile
    class SLEDPodOptionsItem

      attr_reader :internal_hash
      attr_reader :key
      attr_reader :default

      def initialize(key, default)
        @internal_hash = {}
        @key = key
        @default = default
      end

      def value_for_pod(pod_name)
        value = internal_hash[pod_name] || [default]
        value.map do |v|  
          v.nil? ? default : v
        end
      end

      # def sled_all_vlaue=(flag)
      #   internal_hash['all'] = flag
      # end

      def set_value_for_pod(pod_name, value)
        internal_hash[pod_name] ||= []
        internal_hash[pod_name] << value
      end

      def parse_options(name, requirements)
        options = requirements.last
        return requirements unless options.is_a?(Hash)

        should_enable = options.delete(key)
        pod_name = Specification.root_name(name)
        set_value_for_pod(pod_name, should_enable)

        requirements.pop if options.empty?
      end
    end

    class TargetDefinition
      def sled_option_binary 
        @sled_option_binary = SLEDPodOptionsItem.new(:binary, nil) unless @sled_option_binary
        @sled_option_binary
      end

      def sled_option_header_search_paths
        @sled_option_header_search_paths = SLEDPodOptionsItem.new(:hsp, nil) unless @sled_option_header_search_paths
        @sled_option_header_search_paths
      end 

      def sled_parse_sled_options(name, requirements)
        sled_option_binary.parse_options(name, requirements)
        sled_option_header_search_paths.parse_options(name, requirements)
      end

      def sled_inhibit_warnings_if_needed(name, requirements)
        return requirements unless Podfile::DSL.sled_inhibit_all_warnings
        options = requirements.last
        return requirements unless options.is_a?(Hash)
        options[:inhibit_warnings] = true
      end

      original_parse_inhibit_warnings = instance_method(:parse_inhibit_warnings)
      define_method(:parse_inhibit_warnings) do |name, requirements|
        sled_parse_sled_options(name, requirements)
        sled_inhibit_warnings_if_needed(name, requirements)
        original_parse_inhibit_warnings.bind(self).call(name, requirements)
      end
    end
  end
end