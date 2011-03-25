require 'chocbomb/tools/dmg'
require 'chocbomb/tools/xcode'
require 'chocbomb/tools/feed'

module ChocBomb
  module Tasks
    include Tools
    
    def define_tasks
      return unless Object.const_defined?("Rake")
      
      desc "Build #{@name} #{@build_type}"
      task :build => "build/#{@build_type}/#{@name}/Contents/Info.plist"

      task "build/#{@build_type}/#{@name}/Contents/Info.plist" do
        XCode.build(self)
      end
      
      desc "Create the dmg file"
      task :dmg do
        DMG.detach(self)
        DMG.make(self)
        DMG.detach(self)
        DMG.readonly(self)
      end
      
      desc "Create feed"
      task :feed do
        Feed.make_appcast(self)
        Feed.make_dmg_symlink(self)
        Feed.make_index_redirect(self)
        Feed.make_release_notes(self)
      end
      
      desc "All"
      task :appcast => [:build, :dmg, :feed]
    end
  end
end