require_relative 'tool'
require_relative 'podfile/dsl_ext'

module Pod
  class Installer

    class_attr_accessor :sled_force_rsync_local_pod
    self.sled_force_rsync_local_pod = false

    # MARK: force_binary
    class_attr_accessor :sled_force_binary
    self.sled_force_binary = false

    # MARK: sled_reuse_type
    # @return [Array<Symbol>] known reuse options.
    #
    KNOWN_REUSE_OPTIONS = %i(device simulator).freeze

    class_attr_accessor :sled_reuse_type
    self.sled_reuse_type = nil

    def self.sled_should_resure?
      sled_reuse_type && KNOWN_REUSE_OPTIONS.include?(sled_reuse_type)
    end

    def self.sled_reuse_type_name       
      case sled_reuse_type
      when :device then
        "#{Podfile::DSL.sled_configuration}-iphoneos"
      when :simulator then
        "#{Podfile::DSL.sled_configuration}-iphonesimulator"
      else
        "Other"
      end
    end

    def self.sled_reuse_type_desc 
      case sled_reuse_type
      when :device then
        "真机"
      when :simulator then
        "模拟器"
      else
        "Other"
      end
    end

  end
end