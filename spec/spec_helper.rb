# $Id$

begin
  require 'bitwise'
rescue LoadError
  path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  raise if $:.include? path
  $: << path
  retry
end

ENDIAN = ([42].pack('V').unpack('L')[0] == 42) ? :little : :big

# EOF
