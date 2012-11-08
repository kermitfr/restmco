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

#pwd = Dir.pwd
#Daemons.run_proc('mc-rpc-restserver.rb', :dir_mode => :normal, :dir => PIDDIR ) do
#Dir.chdir(pwd)
#exec "ruby /usr/local/bin/kermit/restmco/mc-rpc-restserver.rb"
#end 
require 'rubygems' if RUBY_VERSION < "1.9"
require 'daemons'

$: << File.join(File.dirname(__FILE__), "./")
require 'mc-rpc-restserver'

PIDDIR='/var/run'

app_options = {
      :dir_mode => :normal,
      :dir => PIDDIR,
}

def setid(uname,gname)
  uid = Etc.getpwnam(uname).uid
  gid = Etc.getgrnam(gname).gid
  Process::Sys.setgid(gid)
  Process::Sys.setuid(uid)
end

def getkey(section, key)
    ini=IniFile.load('/etc/kermit/kermit-restmco.cfg', :comment => '#')
    params = ini[section]
    params[key]
end

#Read Configuration file
LOG_FILE = getkey('logger', 'LOG_FILE')
LOG_LEVEL = getkey('logger', 'LOG_LEVEL')

Daemons.run_proc('kermit-restmco', app_options) do
  FileUtils.touch LOG_FILE
  FileUtils.chown('nobody', 'nobody', LOG_FILE)

  #Create Log file
  kermit_log = Logger.new(LOG_FILE)

  case LOG_LEVEL
      when 'DEBUG'
          kermit_log.level = Logger::DEBUG
      when 'INFO'
          kermit_log.level = Logger::INFO
      when 'WARN'
          kermit_log.level = Logger::WARN
      when 'ERROR'
          kermit_log.level = Logger::ERROR
  end

  kermit_log.info "KermIT RestMCO Server started @ " + Time.now.to_s
  KermitRestMCO.set :kermit_log, kermit_log 
  setid('nobody','nobody')
  KermitRestMCO.run!
  kermit_log.info "KermIT RestMCO Server stopped @ " + Time.now.to_s
end
