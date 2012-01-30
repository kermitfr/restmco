# A very simple demonstration of writing a REST server
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
# http://<your box>:4567/mcollective/no-filter/rpcutil/ping/
# http://<your box>:4567/mcollective/no-filter/package/status/package=bash
#
# GET /mcollective/class_filter=retail;class_filter=stores/package/status/package=bash
#
# Returns all the answers as a JSON data block

require 'rubygems'
require 'sinatra'
require 'mcollective'
require 'json'

include MCollective::RPC

uid = Etc.getpwnam("nobody").uid
Process::Sys.setuid(uid)


def set_filters(mc, params)
    if params[:filters] && params[:filters] != 'no-filter' then
        params[:filters].split(';').each do |filter|
            name,value = $1, $2 if filter =~ /^(.+?)=(.+)$/
            puts "#{name}: #{value}"
            case name
            when 'class_filter'
                puts "Applying class_filter"
                mc.class_filter "/#{value}/"
            when 'fact_filter'
                puts "Applying fact_filter"
                mc.fact_filter "#{value}"
            when 'agent_filter'
                puts "Applying agent_filter"
            when 'limit_targets'
                puts "Applying limit_targets"
                mc.limit_targets = "#{value}"
            when 'identity_filter'
                puts "Applying identity_filter"
                mc.identity_filter "#{id_filter(value)}"
            end
        end
    end
end

def id_filter(value)
   value_list = value.split('_OR_')
   if value_list.length > 1
       regex_string = "/"
       value_list.each_with_index do |o,i|
           if i != 0 then
               regex_string << '|'
           end
           regex_string << o
       end
       regex_string << "/"
       return "#{regex_string}"
   end 
   "#{value}"
end 

def arg_parse(params)
    arguments = {}
    params[:splat].each do |args|
        args.split(';').each do |arg|
            arguments[$1.to_sym] = $2 if arg =~ /^(.+?)=(.+)$/
        end
    end
    arguments
end


get '/' do
    "Hello Sinatra"
end

# GET /schedule/in/0s/no-filter/rpcutil/ping/
# GET /schedule/in/60s/identity_filter=el4/package/status/package=bash
get '/schedule/:schedtype/:schedarg/:filters/:agent/:action/*' do
    params[:schedtype] ||='in'
    params[:schedarg]  ||='0s'
    jobreq = { :agentname  => params[:agent],
               :actionname => params[:action],
               :schedtype  => params[:schedtype],
               :schedarg   => params[:schedarg] }
    sched = rpcclient("scheduler")
    set_filters(sched, params)
    arguments = arg_parse(params)
    arguments.each  { |name,value| puts "#{name}: #{value}" }
    unless arguments.empty?
       jobreq[:params] = arguments.keys.join(",")
       jobreq.merge!(arguments)
    end
    JSON.dump(sched.schedule(jobreq).map{|r| r.results})
end

get '/schedstatus/:jobid/:filters' do
   jobreq = { :jobid => params[:jobid] }
   sched = rpcclient("scheduler")
   set_filters(sched, params)
   JSON.dump(sched.query(jobreq).map{|r| r.results})
end

get '/schedoutput/:jobid/:filters' do
   jobreq = { :jobid => params[:jobid], :output => 'yes' }
   sched = rpcclient("scheduler")
   set_filters(sched, params)
   JSON.dump(sched.query(jobreq).map{|r| r.results})
end

get '/mcollective/:filters/:agent/:action/*' do
    mc = rpcclient(params[:agent])
    mc.discover
    set_filters(mc, params)
    arguments = arg_parse(params)
    arguments.each  { |name,value| puts "#{name}: #{value}" }
    JSON.dump(mc.send(params[:action], arguments).map{|r| r.results})
end

