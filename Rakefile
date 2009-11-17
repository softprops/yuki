task :default => :test

task :test do
  sh "ruby test/yuki_test.rb"
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "yuki"
    gemspec.summary = "A Toyko model"
    gemspec.description = "A Toyko model"
    gemspec.email = "d.tangren@gmail.com"
    gemspec.homepage = "http://github.com/softprops/yuki"
    gemspec.authors = ["softprops"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end