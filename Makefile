.PHONY: all cluster build import deploy forward

all: cluster build import deploy forward

cluster:
	k3d cluster create lab --servers 1 --agents 2

build:
	cd packer && packer init . && packer build nginx.pkr.hcl

import:
	k3d image import custom-nginx:latest -c lab

deploy:
	pip install kubernetes --break-system-packages -q
	ansible-galaxy collection install kubernetes.core -q
	ansible-playbook ansible/deploy.yml -e "ansible_python_interpreter=/home/codespace/.python/current/bin/python3"

forward:
	kubectl port-forward svc/custom-nginx-svc 8081:80 >/tmp/nginx.log 2>&1 &
	@echo "Ouvrir le port 8081 dans l'onglet PORTS du Codespace"
