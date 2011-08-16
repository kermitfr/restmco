# A very simple demonstration of writing a REST server
# for Simple RPC clients that takes requests over HTTP
# and returns results as JSON structures.

require 'rubygems'
require 'sinatra'
require 'mcollective'
require 'json'

include MCollective::RPC

# http://<your box>/mcollective/rpctest/echo/msg=hello%20world
#
# Creates a new Simple RPC client for the 'rpctest' agent, calls
# the echo action with a message 'hello world'.
#
# Returns all the answers as a JSON data block

get '/' do
  "Hello Sinatra"
end

get '/mcollective/:filters/:agent/:action/*' do
    mc = rpcclient(params[:agent])
    mc.discover

    if params[:filters] && params[:filters] != 'no-filter' then
    	filters = {}
   	params[:filters].split(';').each do |filter|
        	filters[$1.to_sym] = $2 if filter =~ /^(.+?)=(.+)$/
    	end

    	filters.each do|name,value|
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
			mc.limit_targets "#{value}"
        	elsif name == 'identity_filter' then
			puts "Applying identity_filter"
			mc.identity_filter "#{value}"
		end
    	end
    end
    arguments = {}
    params[:splat].each do |arg|
        arguments[$1.to_sym] = $2 if arg =~ /^(.+?)=(.+)$/
    end

    arguments.each do|name,value|
    	puts "#{name}: #{value}"
    end

    JSON.dump(mc.send(params[:action], arguments).map{|r| r.results})
end
