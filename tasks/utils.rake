# $Id$

require 'fileutils'

namespace :utils do

  desc 'Fix permissions on files'
  task :fix_permissions do
    PROJ.files.each do |fn|
      mod = (fn =~ %r/^bin/ ? 0775 : 0664)
      FileUtils.chmod mod, fn
    end
  end
end

# EOF
