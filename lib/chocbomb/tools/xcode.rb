module ChocBomb
  module Tools
    module XCode
      def self.build(cb)
        sh "xcodebuild -configuration #{cb.build_type} -target #{cb.target} #{cb.build_options}"
      end
    end
  end
end