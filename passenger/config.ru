require 'mc-rpc-restserver'
 
root_dir = File.dirname(__FILE__)

set :environment, :production
set :root,        root_dir
set :app_file,    File.join(root_dir, 'mc-rpc-restserver.rb')
disable :run

def getkey(section, key)
    ini=IniFile.load('/etc/kermit/kermit-restmco.cfg', :comment => '#')
    params = ini[section]
    params[key]
end

#Read Configuration file
LOG_FILE = getkey('logger', 'LOG_FILE')
LOG_LEVEL = getkey('logger', 'LOG_LEVEL')

#Create log file if does not exists
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

run KermitRestMCO

