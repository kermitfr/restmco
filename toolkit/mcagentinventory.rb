#!/usr/bin/ruby
require 'mcollective'
include MCollective::RPC
require 'set'
#require 'json'

# Inspired with these wrappers :
# printrpc rpcutil.agent_inventory()
# help=rpcclient('help')


# Returns the list of all installed agents found when querying the nodes
# regardless of the nodes where the agents are installed
def agentlist(result)
    agents = Set.new
    result.each do |r|
        if r[:statuscode] <= 1
            agents.merge(r[:data][:agents].map{|agent| agent[:agent]})
        end
    end
    return agents.to_a
end

# Returns a hash with the agents installed on each node 
# with some details on the agents
def nodeagentlist(result)
    nodeagents = Hash.new
    result.each do |r|
        if r[:statuscode] <= 1
            nodeagents[r[:sender]] = r[:data]
        end
    end
    return nodeagents
end

# Returns a hash with the agents installed on each node 
# with only the agent names 
def nodeagentnamelist(result)
    nodeagents = Hash.new
    result.each do |r|
        if r[:statuscode] <= 1
            nodeagents[r[:sender]] = r[:data][:agents].map{|agent| agent[:agent]}
        end
    end
    return nodeagents
end


def agentdesc(agentlist)
    adesc = Hash.new    
    agentlist.each do |agentname|
        mcagent=rpcclient(agentname)
        mcagent.verbose = false
        mcagent.progress = false
        mcagent.limit_targets = 1
	actionhash = Hash.new
        begin
            mcagent.ddl.actions.each do |i|
                actiondesc = mcagent.ddl.action_interface(i)
                actionname = actiondesc[:action]
                actionhash[actionname] = actiondesc
            end
        rescue NoMethodError
            next
        end
        adesc[agentname] = actionhash
    end
    return adesc
end

# Main
if __FILE__ == $PROGRAM_NAME
    rpcutil=rpcclient('rpcutil')
    rpcutil.verbose = false
    rpcutil.progress = false
    
    
    RESULT = rpcutil.agent_inventory()
    
    AGENTLIST = agentlist(RESULT)
    pp AGENTLIST
    
    puts
    
    NODEAGENTSNAME = nodeagentnamelist(RESULT) 
    pp NODEAGENTSNAME
    
    puts
    
    NODEAGENTS = nodeagentlist(RESULT) 
    printf("%s =>\n", NODEAGENTS.keys[0])
    pp NODEAGENTS[NODEAGENTS.keys[0]]
    
    puts
    
    ADESC=agentdesc(AGENTLIST)
    printf("%s =>\n", "rpcutil")
    pp ADESC['rpcutil'] 
end
