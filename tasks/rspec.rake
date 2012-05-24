begin
  require 'rspec'
  require 'rspec/core/rake_task'
rescue LoadError
  puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
EOS
end

begin
  require 'rspec/core/rake_task'

  desc "Run the specs under spec/"
  RSpec::Core::RakeTask.new do |t|
#    t.rspec_opts = ['--options', "rspec/rspec.opts"]
#    t.spec_files = FileList['spec/**/*_spec.rb']
    t.pattern = 'spec/**/*_spec.rb'
    t.rspec_opts = ['--backtrace', '--colour']
  end
rescue NameError, LoadError
  # No loss, warning printed already
end
