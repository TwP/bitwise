# $Id$

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'bitwise'

task :default => 'spec:specdoc'

PROJ.name = 'bitwise'
PROJ.authors = 'Tim Pease'
PROJ.email = 'tim.pease@gmail.com'
PROJ.url = 'http://bitwise.rubyforge.org'
PROJ.rubyforge.name = 'bitwise'
PROJ.version = BitWise::VERSION
PROJ.ruby_opts = %w[-W0]

PROJ.spec.opts << '--color'

# make sure the manifest is up to date before building the gem
task 'gem:package' => 'manifest:assert'

# EOF
