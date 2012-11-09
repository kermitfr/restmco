# A very simple REST server
# for Simple RPC clients that takes requests over HTTP
# and returns results as JSON structures.

# Inspired with mcollective/ext/mc-rpc-restserver.rb demo
# in the MCollective source code

# Copyright (C) 2011 Marco Mornati (mornatim at gmail.com)
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

# Examples :
# http://<your box>:4567/mcollective/rpcutil/ping/
# JSON structure :
#{
# filters: {
#   class: ["c1", "c2"],
#   identity: ["i1", "i2"]
#   fact: [ "f1=foo","f2=bar"],
#   agent: [ "a1", "a2"],
#   compound: value
# },
# parameters: {
#   p1name: value,
#   p2name: value
# },
# schedule: {
#   schedtype: value,
#   schedarg: value
# },
# limit: {
#   targets: value,
#   method: value
# },
# timeout: value,
# discoverytimeout: value
#}
#
# Example 1
#
# POST /mcollective/package/status/
# JSON body in POST:
# {
#    "filters": {
#        "class": ['retail', 'stores']
#    },
#    "parameters": {
#        "package": "bash"
#    }
# }
#
# Example 2
#
# POST /mcollective/service/status/
# JSON body :
# {"parameters": {"service":"sshd"}, "limit": {"targets":"1"}}
#
# Example 3
#
# POST /mcollective/service/status/
# JSON body :
# {"filters":{"identity":["notebook", "el6"]}, "parameters": {"service":"sshd"}, "limit": {"targets":"1"}}
#
# Returns all the answers as a JSON document

require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra'
require 'mcollective'
require 'json'
require 'logger'
require 'inifile'
require 'fileutils'

MCO_CONFIG = '/etc/mcollective/client.cfg'
MCO_TIMEOUT = 10 
MCO_DISCOVTMOUT = 4
MCO_DEBUG = false
MCO_COLLECTIVE = nil

class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end

  def symbolize_keys!
     self.replace(self.symbolize_keys)
  end

  def recursive_symbolize_keys!
      symbolize_keys!
      # symbolize each hash in .values
      values.each{|h| h.recursive_symbolize_keys! if h.is_a?(Hash) }
      # symbolize each hash inside an array in .values
      values.select{|v| v.is_a?(Array) }.flatten.each{|h|
      h.recursive_symbolize_keys! if h.is_a?(Hash) }
      self
  end
end

class KermitRestMCO < Sinatra::Base

    set :title, "KermIT RestMCO Server"

    def recursive_symbolize_keys! hash
        hash.symbolize_keys!
        hash.values.select{|v| v.is_a? Hash}.each{|h| recursive_symbolize_keys!(h)}
    end
    
    def set_filters(mc, params)
        if params[:filters] then
            params[:filters].each do |filter_type, filter_values|
                settings.kermit_log.debug "#{filter_type}: #{filter_values.class == Array ? JSON.dump(filter_values) : filter_values}"
                case filter_type
                when :class
                    settings.kermit_log.debug "Applying class_filter"
                    filter_values.each do |value|
                        mc.class_filter "/#{value}/"
                    end
                when :fact
                    settings.kermit_log.debug "Applying fact_filter"
                    filter_values.each do |value|
                        mc.fact_filter "#{value}"
                    end
                when :agent
                    settings.kermit_log.debug "Applying agent_filter"
                    filter_values.each do |value|
                        mc.agent_filter "#{value}"
                    end
                when :identity
                    settings.kermit_log.debug "Applying identity_filter"
                    filter_values.each do |value|
                        mc.identity_filter "#{value}"
                    end
                when :compound
                    settings.kermit_log.debug "Applying compound_filter"
                    settings.kermit_log.debug "compound : #{filter_values}"
                    mc.compound_filter "#{filter_values}"
                end
            end
        end
    end
    
    def set_timeout(mc, params)
        if params[:timeout] then
           settings.kermit_log.debug "Applying timeout"
           settings.kermit_log.debug "timeout : #{params[:timeout]}"
           mc.timeout = params[:timeout]
        end
        if params[:discoverytimeout]
           settings.kermit_log.debug "Applying discovery timeout"
           settings.kermit_log.debug "discovery timeout : #{params[:discoverytimeout]}"
           mc.discovery_timeout = params[:discoverytimeout]
        end
    end
    
    
    get '/' do
        settings.kermit_log.debug "Calling / url"
        "Hello Sinatra"
    end
    
    post '/schedstatus/:jobid/' do
        content_type :json
        settings.kermit_log.debug "Calling /schedstatus url"
        jobreq = { :jobid => params[:jobid] }
        begin
            sched = MCollective::RPC::Client.new("scheduler", 
                :configfile => MCO_CONFIG, 
                :options => {
                        :verbose      => false,
                        :progress_bar => false,
                        :timeout      => MCO_TIMEOUT,
                        :config       => MCO_CONFIG,
                        :filter       => MCollective::Util.empty_filter,
                        :collective   => MCO_COLLECTIVE,
                })
        rescue Exception => e
            settings.kermit_log.error e.message
        end
        if sched.nil?
            return JSON.dump([{"sender"=>"ERROR","statuscode"=>1,"statusmsg"=>"ERROR","data"=>{"message"=>e.message}}])
        end
        body_content = request.body.read
        data = (body_content.nil? or body_content.empty?) ? {} : recursive_symbolize_keys(JSON.parse(body_content))
        set_filters(sched, data)
        json_response = JSON.dump(sched.query(jobreq).map{|r| r.results})
        settings.kermit_log.info "Command schedstatus #{params[:jobid]} executed on filters #{JSON.dump(data[:filters])}"
        settings.kermit_log.debug "Response received: #{json_response}"
        json_response
    end
    
    post '/schedoutput/:jobid/' do   
        content_type :json
        settings.kermit_log.debug "Calling /schedoutput url"
        jobreq = { :jobid => params[:jobid], :output => 'yes' }
        begin
            sched = MCollective::RPC::Client.new("scheduler", 
                    :configfile => MCO_CONFIG, 
                    :options => {
                        :verbose      => false,
                        :progress_bar => false,
                        :timeout      => MCO_TIMEOUT,
                        :config       => MCO_CONFIG,
                        :filter       => MCollective::Util.empty_filter,
                        :collective   => MCO_COLLECTIVE,
                    } )
        rescue Exception => e
            settings.kermit_log.error e.message
        end
        if sched.nil?
            return JSON.dump([{"sender"=>"ERROR","statuscode"=>1,"statusmsg"=>"ERROR","data"=>{"message"=>e.message}}])
        end
        body_content = request.body.read
        data = (body_content.nil? or body_content.empty?) ? {} : recursive_symbolize_keys(JSON.parse(body_content))
        set_filters(sched, data)
        json_response = JSON.dump(sched.query(jobreq).map{|r| r.results})
        settings.kermit_log.info "Command scheoutput #{params[:jobid]} executed on filters: #{JSON.dump(data[:filters])}"
        settings.kermit_log.debug "Response received: #{json_response}"
        json_response
    end
    
    post '/mcollective/:agent/:action/' do
        content_type :json
        settings.kermit_log.debug "Calling /mcollective url Agent: #{params[:agent]} Action:#{params[:action]}"
        body_content = request.body.read
        data = (body_content.nil? or body_content.empty?) ? {} : JSON.parse(body_content)
        data.recursive_symbolize_keys!
        settings.kermit_log.debug "JSON Data: #{JSON.dump(data)}"
        if data[:schedule] then
            settings.kermit_log.info "Executing with backend scheduler"
            scheduler_data=data[:schedule]
            scheduler_data[:schedtype] ||='in'
            scheduler_data[:schedarg]  ||='0s'
            jobreq = { :agentname  => params[:agent],
                       :actionname => params[:action],
                       :schedtype  => scheduler_data[:schedtype],
                       :schedarg   => scheduler_data[:schedarg] }
            begin
                sched = MCollective::RPC::Client.new("scheduler", 
                        :configfile => MCO_CONFIG, 
                        :options => {
                            :verbose      => false,
                            :progress_bar => false,
                            :timeout      => MCO_TIMEOUT,
                            :config       => MCO_CONFIG,
                            :filter       => MCollective::Util.empty_filter,
                            :collective   => MCO_COLLECTIVE,
                        } )
            rescue Exception => e
                settings.kermit_log.error e.message
            end
            if sched.nil?
                return JSON.dump([{"sender"=>"ERROR","statuscode"=>1,"statusmsg"=>"ERROR","data"=>{"message"=>e.message}}])
            end

            set_filters(sched, data)
            unless data[:parameters].nil? or data[:parameters].empty?
                jobreq[:params] = data[:parameters].keys.join(",")
                jobreq.merge!(data[:parameters])
            end
            json_response = JSON.dump(sched.schedule(jobreq).map{|r| r.results})
            settings.kermit_log.info "Command Agent: #{params[:agent]} Action: #{params[:action]} executed"
            settings.kermit_log.debug "Response received: #{json_response}"
            json_response
        else
            begin
                mc = MCollective::RPC::Client.new(params[:agent], 
                    :configfile => MCO_CONFIG, 
                    :options => {
                        :verbose      => false,
                        :progress_bar => false,
                        :timeout      => MCO_TIMEOUT,
                        :config       => MCO_CONFIG,
                        :filter       => MCollective::Util.empty_filter,
                        :collective   => MCO_COLLECTIVE,
                    })
            rescue Exception => e
                settings.kermit_log.error e.message
            end
            if mc.nil?
                return JSON.dump([{"sender"=>"ERROR","statuscode"=>1,"statusmsg"=>"ERROR","data"=>{"message"=>e.message}}])
            end
            mc.discover
            set_filters(mc, data)
            set_timeout(mc, data)
            if data[:parameters]
                data[:parameters].each  { |name,value| puts "#{name}: #{value}" }
            end
            if data[:limit]
                limits = data[:limit]
                if limits[:targets]
                    mc.limit_targets = "#{limits[:targets]}"
                end
                if limits[:method]
                    mc.limit_method = "#{limits[:method]}"
                end
            end
    
            json_response = JSON.dump(mc.send(params[:action], data[:parameters]).map{|r| r.results})
            settings.kermit_log.info "Command Agent: #{params[:agent]} Action: #{params[:action]} executed"
            settings.kermit_log.debug "Response received: #{json_response}"
            json_response
        end
    end
end 

if __FILE__ == $0
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
    KermitRestMCO.run!
    kermit_log.info "KermIT RestMCO stopped @ " + Time.now.to_s
end
