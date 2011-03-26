require 'chocbomb/tools/images'

module ChocBomb
  module Tools    
    class DMG
      attr_accessor :chocbomb
      def initialize(cb)
        @chocbomb = cb
        @files_for_dmg = {}
      end
      
      def self.detach(cb)
        self.new(cb).detach
      end
      
      def self.make(cb)
        self.new(cb).make
      end
      
      
      def self.readonly(cb)
        self.new(cb).readonly
      end
      
      def detach
        mounted_paths = `hdiutil info | grep '#{chocbomb.volume_path}' | grep "Apple_HFS"`.split("\n").map { |e| e.split(" ").first }
        mounted_paths.each do |path|
          begin
            sh "hdiutil detach '#{path}' -quiet -force"
          rescue StandardError => e
            p e
          end
        end
      end
      
      def make        
        @files_for_dmg = chocbomb.files.inject({}) do |files, file|
          path_or_helper, options = file
          path = case path_or_helper
            when Symbol
              chocbomb.send path_or_helper
            when Proc
              path_or_helper.call
            else
              path_or_helper
          end
          if path && File.exists?(path)
            files[path] = options 
            options[:name] ||= File.basename(path)
          end
          if path =~ %r{\.webloc$}
            files[path] = options 
            options[:name] ||= File.basename(path)
            options[:link] = true
          end
          files
        end

        FileUtils.rm_r(chocbomb.dmg_src_folder) if File.exists? chocbomb.dmg_src_folder
        FileUtils.mkdir_p(chocbomb.dmg_src_folder)
        
        @files_for_dmg.each do |path, options|
          if options[:link]
            webloc = <<-WEBLOC.gsub(/^      /, '')
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            	<key>URL</key>
            	<string>#{options[:url]}</string>
            </dict>
            </plist>
            WEBLOC

            target = File.join(chocbomb.dmg_src_folder, options[:name])
            File.open(target, 'w').write(webloc)
          else
            target = File.join(chocbomb.dmg_src_folder, options[:name])
            FileUtils.copy_entry(path, target)      
            if options[:exclude]
              exclude_list = options[:exclude].is_a?(Array) ? options[:exclude] : [options[:exclude].to_s]
              exclude_list.each { |exclude| sh ::Escape.shell_command(['rm', '-rf', File.join(target, exclude)]) }
            end
          end
        end
                
        FileUtils.mkdir_p chocbomb.build_path
        FileUtils.rm_f(chocbomb.pkg)
        sh "hdiutil create -format UDRW -quiet -volname '#{chocbomb.name}' -srcfolder '#{chocbomb.dmg_src_folder}' '#{chocbomb.pkg}'"
        mount
        sh "bless --folder '#{chocbomb.volume_path}' --openfolder '#{chocbomb.volume_path}'"
        sh "sleep 1"
        
        # Add Volume Icon
        FileUtils.cp(chocbomb.volume_icon, "#{chocbomb.volume_path}/.VolumeIcon.icns")
        sh "SetFile -a C '#{chocbomb.volume_path}'"
        
        # Configure Application Icon
        Mac.applescript <<-SCRIPT.gsub(/^      /, ''), "apps_icon_script"
          tell application "Finder"
            set applications_folder to displayed name of (path to applications folder) -- i18n
            set dest to disk "#{chocbomb.name}"
            set src to folder applications_folder of startup disk
            make new alias at dest to src
          end tell
        SCRIPT
        
        # Configure DMG Window
        if chocbomb.background_file
          target_background = "#{chocbomb.volume_path}/#{chocbomb.volume_background}"
          FileUtils.mkdir_p(File.dirname(target_background))
          FileUtils.cp(chocbomb.background_file, target_background) 
        end
        Mac.applescript <<-SCRIPT.gsub(/^      /, '')
          tell application "Finder"
             set applications_folder to displayed name of (path to applications folder) -- i18n
             set mountpoint to POSIX file ("#{chocbomb.volume_path}" as string) as alias
             tell folder mountpoint
                 open
                 tell container window
                    set toolbar visible to false
                    set statusbar visible to false -- doesn't do anything at DMG open time
                    set current view to icon view
                    delay 1 -- Sync
                    set the bounds to {#{window_bounds.join(", ")}}
                 end tell
                 delay 1 -- Sync
                 set icon size of the icon view options of container window to #{chocbomb.icon_size}
                 set text size of the icon view options of container window to #{chocbomb.icon_text_size}
                 set arrangement of the icon view options of container window to not arranged
                 #{set_position_of_files}
                 #{set_position_of_shortcuts}
                 close
                 open
                 set the bounds of the container window to {#{window_bounds.join(", ")}}
                 set background picture of the icon view options of container window to file "#{chocbomb.volume_background.gsub(/\//,':')}"
                 update without registering applications
                 delay 5 -- Sync
                 close
             end tell
             -- Sync
             delay 5
          end tell
        SCRIPT
        sh "SetFile -a V '#{target_background}'" if chocbomb.background_file
      end
      
      def readonly
        tmp_path = "/tmp/#{chocbomb.name}-rw.dmg"
        FileUtils.mv(chocbomb.pkg, tmp_path)
        sh "hdiutil convert '#{tmp_path}' -format UDZO -imagekey zlib-level=9 -o '#{chocbomb.pkg}'"
      end    

      private
      def mount
        sh "hdiutil attach '#{chocbomb.pkg}' -mountpoint '#{chocbomb.volume_path}' -noautoopen -quiet"
      end
          
      def window_position
        [50, 100]
      end

      def window_bounds
        window_position + 
        window_position.zip(background_bounds).map { |w, b| w + b }
      end

      def background_bounds
        return [400, 300] unless chocbomb.background_file
        return ChocBomb::Tools::Images.size(chocbomb.background_file)
      end
    
      def set_position_of_files
        @files_for_dmg.map do |file_options|
          path, options = file_options
          target        = options[:name]
          position      = options[:position].join(", ")
          %Q{set position of item "#{target}" to {#{position}}}
        end.join("\n")
      end

      def set_position_of_shortcuts
        if include_applications_icon?
          %Q{set position of item applications_folder to {#{chocbomb.applications_icon_position.join(", ")}}}
        else
          ""
        end
      end
      
      def include_applications_icon?
        # target =~ /.app$/
        true
      end
    end
    
    module AppCast
    end
    
    module Mac
      def self.applescript(applescript, tmp_file = "chocbomb-script")
        File.open(scriptfile = "/tmp/#{tmp_file}", "w") do |f|
          f << applescript
        end
        sh("osascript #{scriptfile}") do |ok, res|
          if ! ok
            p res
            exit 1
          end
        end
        applescript
      end
    end
  end
end