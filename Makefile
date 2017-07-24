DCOS_ENDPOINT = [URL to your DCOS cluster]
APIGATEWAY_DNS = [DNS to your api-gateway]
UNIVERSE_REPO = [URL to your universe repo.json]

.PHONY: dcos-cli
dcos-cli:
	rm dcos
	curl -O https://downloads.dcos.io/binaries/cli/darwin/x86-64/dcos-1.9/dcos
	chmod +x dcos
	./dcos --version
	dcos config set core.dcos_url $(DCOS_ENDPOINT)

.PHONY: dcos-repo
dcos-repo:
	./dcos package repo add --index=0 openwhisk-universe $(UNIVERSE_REPO)

.PHONY: dcos-install
dcos-install: exhibitor kafka couchdb consul registrator whisk-controller whisk-invoker

.PHONY: apigateway
apigateway:
	yes | ./dcos package install apigateway --options=config/apigateway.json

.PHONY: exhibitor
exhibitor:
	yes | ./dcos package install exhibitor
	echo "waiting until all the exhibitor instances are up (serving) ... "
	until (curl -sS http://exhibitor-dcos.gw.$(APIGATEWAY_DNS)/exhibitor/v1/cluster/status | jq . | grep "serving" | wc -l | grep 3); do printf '.'; sleep 5; done
	echo "exhibitor is up!"

# TODO: kafka is notified healthy when one of the brokers is up. Is it good enough?
.PHONY: kafka
kafka:
	if (curl -sS http://exhibitor-dcos.gw.$(APIGATEWAY_DNS)/exhibitor/v1/cluster/status | jq . | grep "serving" | wc -l | grep 3); then \
		echo "exhibitor is running. installing kafka ... "; \
		yes | ./dcos package install kafka --options=config/kafka.json; \
		until (curl -s http://kafka.gw.$(APIGATEWAY_DNS)/admin/healthcheck | grep "All expected Brokers running"); do printf '.'; sleep 5; done; \
		echo "kafka is up!"; \
	else \
		echo "Exhibitor is not running. Cancelling kafka installation."; \
	fi

.PHONY: couchdb
couchdb:
	echo "installing whisk-couchdb ... "
	yes | ./dcos package install whisk-couchdb
	until (curl -s -I http://whisk-couchdb.gw.$(APIGATEWAY_DNS)/_stats | grep "HTTP/1.1 200 OK"); do printf '.'; sleep 5; done
	echo "couchdb is up!"

.PHONY: consul
consul:
	echo "installing consul ... "
	yes | ./dcos package install consul
	sleep 40
	echo "consul is up!"

# TODO Dependency: verify consul is running
.PHONY: registrator
registrator:
	echo "installing registrator ... "
	yes | ./dcos package install registrator
	sleep 40
	echo "registrator is up!"

.PHONY: whisk-controller
whisk-controller:
	if (curl -s http://kafka.gw.$(APIGATEWAY_DNS)/admin/healthcheck | grep "All expected Brokers running"); then \
		echo "installing whisk-controller ... "; \
		yes | ./dcos package install whisk-controller; \
		until (curl -s http://whisk-controller.gw.$(APIGATEWAY_DNS)/ping | grep "pong"); do printf '.'; sleep 5; done; \
		echo "whisk-controller is up!"; \
	else \
		echo "Some prerequisite service (kafka/consul) is not running. Cancelling whisk-controller installation."; \
	fi

.PHONY: whisk-invoker
whisk-invoker:
	if (curl -s http://whisk-controller.gw.$(APIGATEWAY_DNS)/ping | grep "pong"); then \
		echo "installing whisk-invoker ... "; \
		yes | ./dcos package install whisk-invoker; \
		until (curl -s http://whisk-controller.gw.$(APIGATEWAY_DNS)/invokers | grep "up"); do printf '.'; sleep 5; done; \
		echo "whisk-invoker is up!"; \
	else \
		echo "whisk-controller is not running. Cancelling whisk-invoker installation."; \
	fi
