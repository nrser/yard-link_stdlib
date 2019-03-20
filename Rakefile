require "bundler/gem_tasks"
require "rspec/core/rake_task"


RSpec::Core::RakeTask.new(:spec)


desc %(Run `yard doctest` on all lib Ruby files with `# doctest: true` comment)
task :doctest do
  paths = Dir[ './lib/**/*.rb' ].select do |path|
    File.open( path, 'r' ).each_line.lazy.take( 32 ).find do |line|
      line.start_with? '# doctest: true'
    end
  end
  
  sh %(yard doctest #{ paths.shelljoin })
end # task :doctest


task :default => [ :spec, :doctest ]
