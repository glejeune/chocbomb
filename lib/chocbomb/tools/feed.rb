require 'builder'
require 'RedCloth'

module ChocBomb
  module Tools
    class Feed
      attr_accessor :chocbomb
      def initialize(cb)
        @chocbomb = cb
      end
      
      def self.make_appcast(cb)
        self.new(cb).make_appcast
      end
      
      def self.make_dmg_symlink(cb)
        self.new(cb).make_dmg_symlink
      end
      
      def self.make_index_redirect(cb)
        self.new(cb).make_index_redirect
      end
      
      def self.make_release_notes(cb)
        self.new(cb).make_release_notes
      end
      
      def make_appcast
        FileUtils.mkdir_p(chocbomb.build_path)
        appcast = File.open("#{chocbomb.build_path}/#{chocbomb.appcast_filename}", 'w') do |f|
          xml = Builder::XmlMarkup.new(:indent => 2)
          xml.instruct!
          xml_string = xml.rss('xmlns:atom' => "http://www.w3.org/2005/Atom",
                               'xmlns:sparkle' => "http://www.andymatuschak.org/xml-namespaces/sparkle",
                               :version => "2.0") do
            xml.channel do
              xml.title(chocbomb.name)
              xml.description("#{chocbomb.name} updates")
              xml.link(chocbomb.base_url)
              xml.language('en')
              xml.pubDate( Time.now.strftime("%a, %d %b %Y %H:%M:%S %z") )
              # xml.lastBuildDate(Time.now.rfc822)
              xml.atom(:link, :href => "#{chocbomb.base_url}/#{chocbomb.appcast_filename}",
                       :rel => "self", :type => "application/rss+xml")

              xml.item do
                xml.title("#{chocbomb.name} #{chocbomb.version}")
                xml.tag! "sparkle:releaseNotesLink", "#{chocbomb.base_url}/#{chocbomb.release_notes}"
                xml.pubDate Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
                xml.guid("#{chocbomb.name}-#{chocbomb.version}", :isPermaLink => "false")
                xml.enclosure(:url => "#{chocbomb.base_url}/#{chocbomb.pkg_name}",
                              :length => "#{File.size(chocbomb.pkg)}",
                              :type => "application/dmg",
                              :"sparkle:version" => chocbomb.version,
                              :"sparkle:dsaSignature" => chocbomb.dsa_signature)
              end
            end
          end
          f << xml_string
        end
      end
      
      def make_dmg_symlink
        if chocbomb.pkg_name != chocbomb.versionless_pkg_name
          FileUtils.chdir(chocbomb.build_path) do
            `rm '#{chocbomb.versionless_pkg_name}'`
            `ln -s '#{chocbomb.pkg_name}' '#{chocbomb.versionless_pkg_name}'`
          end
        end
      end
      
      def make_index_redirect
        File.open("#{chocbomb.build_path}/index.php", 'w') do |f|
          f << %Q{<?php header("Location: #{chocbomb.pkg_relative_url}"); ?>}
        end
      end
      
      def make_release_notes
        if File.exist?(chocbomb.release_notes_template)
          File.open("#{chocbomb.build_path}/#{chocbomb.release_notes}", "w") do |f|
            template = File.read(chocbomb.release_notes_template)
            f << ERB.new(template).result(binding)
          end
        end
      end
      
      def release_notes_content
        if File.exists?("release_notes.txt")
          File.read("release_notes.txt")
        else
          <<-TEXTILE.gsub(/^      /, '')
          h1. #{version} #{Date.today}

          h2. Another awesome release!
          TEXTILE
        end
      end

      def release_notes_html
        RedCloth.new(release_notes_content).to_html
      end
    end
  end
end