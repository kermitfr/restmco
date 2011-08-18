#!/usr/bin/ruby
require 'rubygems'
require 'daemons'

PIDDIR='/tmp'

# We need KILL instead of TERM for sinatra
original_verbosity = $VERBOSE
$VERBOSE = nil
Daemons::Application::SIGNAL = 'KILL'
$VERBOSE = original_verbosity

pwd = Dir.pwd
Daemons.run_proc('mc-rpc-restserver.rb', :dir_mode => :normal, :dir => PIDDIR ) do
Dir.chdir(pwd)
exec "ruby /usr/local/bin/kermit/restmco/mc-rpc-restserver.rb"
end 

