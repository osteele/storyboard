require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.libs << 'test'
    t.test_files = FileList['test/**/*_test.rb']
    t.rcov_opts = ["-T -x '/Library/Ruby/*'"]
    t.verbose = true
  end
rescue LoadError
  $stderr.puts "Rcov not available. Install it for rcov-related tasks with:"
  $stderr.puts "  sudo gem install rcov"
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = 'storyboard'
    s.summary = "A DSL for writing  explanatorymathematical narratives."
    s.description = "Storyboard is an animation language, currently built on top of Ruby-Processing, for creating explanatory mathematical narratives."
    s.email = "steele@osteele.com"
    s.homepage = "http://github.com/osteele/storyboard"
    s.authors = ["Oliver Steele"]
    s.has_rdoc = true
    s.extra_rdoc_files = %w[README.rdoc LICENSE.txt TODO.txt]
    s.files = FileList["[A-Z]*", "{bin,lib,test}/**/*"]
    s.add_dependency 'ruby-processing'
  end

rescue LoadError
  $stderr.puts "Jeweler not available. Install it for jeweler-related tasks with:"
  $stderr.puts "  sudo gem install jeweler"
end

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'test'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :test
