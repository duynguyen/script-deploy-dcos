Deploy script for OpenWhisk on DC/OS
====================================

### Pre-requisites
You need to build the DC/OS packages for OpenWhisk components and store the universe file (`repo.json`) on a hosting service (e.g. S3). Currently the packages can be built from this PR: https://github.com/apache/incubator-openwhisk-devtools/pull/20.

### Environment Setup
* A DC/OS cluster with at least 3 * m3.xlarge slaves [0]
* Set the value for `DCOS_ENDPOINT`, `APIGATEWAY_DNS` and `UNIVERSE_REPO`
* Run the command `make dcos-cli` to install CLI tool
* `./dcos auth login`, follow the instruction to log into DC/OS
* Configure the DC/OS cluster to use OpenWhisk's Universe repository: `make dcos-repo`
* Install the APIGateway package with `make apigateway`
* Set up your DNS service (e.g. AWS Route 53) to link to this APIGateway endpoint
* Install all the remaining packages with `make dcos-install`

### References
[0] https://dcos.io/docs/1.9/installing/cloud/aws/basic/
