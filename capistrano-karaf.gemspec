Gem::Specification.new do |s|
  s.name          = 'capistrano-karaf'
  s.version       = '1.5.1'
  s.date          = '2014-03-20'
  s.summary       = 'Capistrano functions for communicating with karaf'
  s.authors       = ['Brecht Hoflack','Jerome Morel']
  s.email         = 'brecht.hoflack@gmail.com'
  s.files         = [ 'lib/capistrano-karaf.rb', 
                      'lib/capistrano-karaf/core.rb', 
                      'lib/capistrano-karaf/extended.rb',
                      'lib/capistrano-karaf/semver.rb',
                      'lib/capistrano-karaf/install.rb' ]
  s.homepage      = 'http://github.com/bhoflack/capistrano-karaf'
  s.license       = 'bsd'
end
