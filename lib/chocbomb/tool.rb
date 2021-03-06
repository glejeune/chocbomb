require 'erb'

module ChocBomb
  def self.create
    templates = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "templates"))
    data = ERB.new(open(File.join(templates, "Rakefile.erb")).read).result(binding)
    File.open("Rakefile", 'w') {|f| f.write(data) }
  end
end
