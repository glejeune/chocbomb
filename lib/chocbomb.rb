require 'uri'
require 'rubygems'
require 'plist'
require 'escape'
require 'chocbomb/rake/tasks'
require 'erb'

module ChocBomb
  class Configuration
    include Tasks
    
    attr_accessor :host
    attr_accessor :base_url
    attr_accessor :su_feed_url
    
    attr_accessor :release_notes
    attr_accessor :private_key
    
    attr_accessor :minimum_osx_version
    
    # The background image
    attr_accessor :background_file
    
    # Position of the icon app
    attr_accessor :app_icon_position
    
    # Position of the Application symlink icon
    attr_accessor :applications_icon_position
    
    # Icns for the volume icon
    attr_accessor :volume_icon

    # Build type (Release, Debug, ...)
    attr_accessor :build_type

    # Target
    attr_accessor :target
    
    # Build options
    attr_accessor :build_options
    
    attr_accessor :icon_size
    attr_accessor :icon_text_size
    
    # Add an explicit file/bundle/folder into the DMG
    # Examples:
    #   file 'build/Release/SampleApp.app', :position => [50, 100]
    #   file :target_bundle, :position => [50, 100]
    #   file proc { 'README.txt' }, :position => [50, 100]
    #   file :position => [50, 100] { 'README.txt' }
    # Required option:
    #   +:position+ - two item array [x, y] window position
    # Options:
    #   +:name+    - override the name of the project when mounted in the DMG
    #   +:exclude+ - do not include files/folders
    def file(*args, &block)
      path_or_helper, options = args.first.is_a?(Hash) ? [block, args.first] : [args.first, args.last]
      throw "add_files #{path_or_helper}, :position => [x,y] option is missing" unless options[:position]
      
      @files[path_or_helper] = options
    end
    
    # Add the whole project as a mounted item; e.g. a TextMate bundle
    # Examples:
    #   add_link "http://github.com/drnic/choctop", :name => 'Github', :position => [50, 100]
    #   add_link "http://github.com/drnic/choctop", 'Github.webloc', :position => [50, 100]
    # Required option:
    #   +:position+ - two item array [x, y] window position
    #   +:name+    - override the name of the project when mounted in the DMG
    def link(url, *options)
      name = options.first if options.first.is_a?(String)
      options = options.last || {}
      options[:url] = url
      options[:name] = name if name
      throw "add_link :position => [x,y] option is missing" unless options[:position]
      throw "add_link :name => 'Name' option is missing" unless options[:name]
      options[:name].gsub!(/(\.webloc|\.url)$/, '')
      options[:name] += ".webloc"
      
      @files[options[:name]] = options
    end
    
    def initialize
      @plist = Plist::parse_xml(File.expand_path('Info.plist'))
      @files = {}

      yield self if block_given?
      
      default
      define_tasks
    end
    
    attr_reader :name
    attr_reader :version
    attr_reader :volume_path
    attr_reader :build_path
    attr_reader :pkg_name
    attr_reader :pkg
    attr_reader :dmg_src_folder
    attr_reader :bundle
    attr_reader :volume_background

    attr_reader :files
    
    attr_reader :appcast_filename
    attr_reader :dsa_signature
    
    attr_reader :versionless_pkg_name
    attr_reader :pkg_relative_url
    
    attr_reader :release_notes_template
    attr_reader :release_notes
    
    private 
    def default
      @name = @plist['CFBundleExecutable'] || File.basename(File.expand_path("."))
      @name = File.basename(File.expand_path(".")) if @name == '${EXECUTABLE_NAME}'
      @version = @plist['CFBundleVersion']
      
      @su_feed_url ||= @plist['SUFeedURL']
      @base_url ||= File.dirname(su_feed_url)
      @host ||= URI.parse(base_url).host
      @release_notes ||= 'release_notes.html'
      
      @background_file ||= File.expand_path(File.join(File.dirname(__FILE__), "..", "templates", "default_background.jpg"))
      @app_icon_position ||= [175, 65]
      @applications_icon_position ||= [347, 270]
      @volume_icon ||= File.expand_path(File.join(File.dirname(__FILE__), "..", "templates", "default_volume.icns"))
      @build_type ||= ENV['BUILD_TYPE'] || 'Release'
      @target ||= @name
      @build_options ||= ''
      
      @icon_size ||= 104
      @icon_text_size ||= 12
            
      @volume_path = "/Volumes/#{@name}"
      @build_path = "appcast/build"
      @pkg_name = "#{@name}-#{@version}.dmg"
      @pkg = "#{@build_path}/#{@pkg_name}"
      @dmg_src_folder = "build/#{@build_type}/dmg"
      @bundle = Dir["build/#{@build_type}/#{@name}.*"].first
      @volume_background = ".background/background#{File.extname(@background_file)}"
      file :bundle, :position => @app_icon_position
      
      @appcast_filename ||= su_feed_url ? File.basename(su_feed_url) : 'my_feed.xml'
      @private_key ||= File.expand_path('dsa_priv.pem')
      
      @versionless_pkg_name = "#{@name}.dmg"
      @pkg_relative_url = "#{@base_url.gsub(%r{/$}, '')}/#{@pkg_name}".gsub(%r{^.*#{@host}}, '')
      
      @release_notes_template = "release_notes_template.html.erb"
      
      @minimum_osx_version ||= nil
    end
  end
end
