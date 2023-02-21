
default:
	just --list

# Deploy infrastructure via bicep
deploy-infra-bicep:
	./scripts/deploy-infra-bicep.sh

# Get kubectl login
get-kube-login:
	./scripts/get-kube-login.sh
