Gem::Specification.new do |s|
  s.name          = 'capistrano-karaf'
  s.version       = '1.4.2'
  s.date          = '2014-01-23'
  s.summary       = 'Capistrano functions for communicating with karaf'
  s.authors       = ['Brecht Hoflack']
  s.email         = 'brecht.hoflack@gmail.com'
  s.files         = [ 'lib/capistrano-karaf.rb', 
                      'lib/capistrano-karaf/core.rb', 
                      'lib/capistrano-karaf/extended.rb',
                      'lib/capistrano-karaf/semver.rb',
                      'lib/capistrano-karaf/install.rb' ]
  s.homepage      = 'http://github.com/bhoflack/capistrano-karaf'
  s.license       = 'bsd'
end
