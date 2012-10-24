This project creates a simple REST server that you can use to communicate with
MCollective (rpc communication).

You can reach MCollective with URLs like :

POST on http://yourserver:4567/mcollective/rpcutil/ping/ # Sinatra standalone
POST on http://yourserver/mcollective/rpcutil/ping/ # Passenger

Depending on if you use Sinatra as a standalone service or through Apache and
Passenger.

With curl :

    curl -X POST http://yourserver/mcollective/rpcutil/ping/; echo

The syntax is /mcollective/agent/action/ with a POST request

Examples of use:

POST on http://yourserver/mcollective/rpcutil/ping/, 
With Content-Type = "application/json", 
With POST body = {"filters":{"identity":["el5.labolinux.fr","el6.labolinux.fr"]}}

POST on http://yourserver/mcollective/rpcutil/ping/
With Content-Type = "application/json"
With POST body = {"filters":{"fact":["rubyversion=1.8.7"]}}

With curl :

    curl -X POST -H 'content-type: application/json' -d \
    '{"filters":{"fact":["rubyversion=1.8.7"]}}' \
    http://yourserver/mcollective/rpcutil/ping/; echo

POST on http://yourserver/mcollective/rpcutil/ping/
With Content-Type = "application/json"
With POST body = {"limit":{"method":"random","targets":1},"filters":{}}

POST on http://yourserver/mcollective/package/status/
With Content-Type = "application/json"
With POST body = {"filters":{"class":["postgresql-server"]},"parameters":{"package":"postgresql"}}

POST on http://yourserver/mcollective/package/status/
With Content-Type = "application/json"
With POST body = {"filters":{"compound":"(operatingsystem=CentOS and !operatingsystemrelease=6.3)"},"parameters":{"package":"bash"}}

With curl :

   curl -X POST -H 'content-type: application/json' -d \
   '{"filters":{"compound":"(operatingsystem=CentOS and !operatingsystemrelease=6.3)"},"parameters":{"package":"bash"}}' \
    http://yourserver/mcollective/package/status/


POST on http://yourserver/mcollective/service/status/, 
With Content-Type = "application/json", 
With POST body = {"filters":{"identity":["el5.labolinux.fr"],"class":["postgresql-server"]},"parameters":{"service":"sshd"}}

The installation documentation is available here :

http://www.kermit.fr/kermit/doc/restmco/install.html
