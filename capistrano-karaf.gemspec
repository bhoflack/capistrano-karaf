Gem::Specification.new do |s|
  s.name          = 'capistrano-karaf'
  s.version       = '1.8.8'
  s.date          = '2015-06-19'
  s.summary       = 'Capistrano functions for communicating with karaf'
  s.authors       = ['Brecht Hoflack']
  s.email         = 'brecht.hoflack@gmail.com'
  s.files         = [ 'lib/capistrano-karaf.rb', 
                      'lib/capistrano-karaf/core.rb', 
                      'lib/capistrano-karaf/extended.rb',
                      'lib/capistrano-karaf/semver.rb',
                      'lib/capistrano-karaf/install.rb',
                      'lib/capistrano-karaf/docker.rb',
                      'lib/capistrano-karaf/backends/opensshproxy.rb' ]
  s.homepage      = 'http://github.com/bhoflack/capistrano-karaf'
  s.license       = 'bsd'
end
