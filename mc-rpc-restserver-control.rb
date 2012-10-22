#!/usr/bin/ruby

# Copyright (C) 2011 Louis Coilliot (louis.coilliot at gmail.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


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

