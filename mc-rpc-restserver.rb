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

require 'rubygems'
require 'sinatra'
require 'mcollective'
require 'json'

include MCollective::RPC

uid = Etc.getpwnam("nobody").uid
Process::Sys.setuid(uid)

# Examples :
# http://<your box>:4567/mcollective/no-filter/rpcutil/ping/
# http://<your box>:4567/mcollective/no-filter/package/status/package=bash
#
# Returns all the answers as a JSON data block

get '/' do
    "Hello Sinatra"
end

get '/mcollective/:filters/:agent/:action/*' do
    mc = rpcclient(params[:agent])
    mc.discover

    if params[:filters] && params[:filters] != 'no-filter' then
        params[:filters].split(';').each do |filter|
            name,value = $1, $2 if filter =~ /^(.+?)=(.+)$/
            puts "#{name}: #{value}"
            if name == 'class_filter' then
                puts "Applying class_filter"
                mc.class_filter "/#{value}/"
            elsif name == 'fact_filter' then
                puts "Applying fact_filter"
                mc.fact_filter "#{value}"
            elsif name == 'agent_filter' then
                puts "Applying agent_filter"
            elsif name == 'limit_targets' then
                puts "Applying limit_targets"
                mc.limit_targets="#{value}"
            elsif name == 'identity_filter' then
                puts "Applying identity_filter"
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
                    mc.identity_filter "#{regex_string}"
                else
                    mc.identity_filter "#{value}"
                end
            end
        end
    end

    arguments = {}

    params[:splat].each do |args|
        args.split(';').each do |arg|
            arguments[$1.to_sym] = $2 if arg =~ /^(.+?)=(.+)$/
        end
    end

    arguments.each do|name,value|
        puts "#{name}: #{value}"
    end

    JSON.dump(mc.send(params[:action], arguments).map{|r| r.results})
end

