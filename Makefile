SHELL = /bin/bash
REGISTRY := registry.local:5000
IMAGE := my-echo

.PHONY: integration-up
integration-up: TAG := $(shell date +"%Y-%m-%d-%I-%M-%S")
integration-up: FULL_IMAGE := $(REGISTRY)/$(IMAGE):$(TAG)
integration-up: REPLACE_IMAGE := $(REGISTRY)\/$(IMAGE):$(TAG)
integration-up:
	@echo
	@echo "Start K3s cluster and registry locally."
	docker-compose \
	-f ./docker-compose.yaml \
	-f ./docker-compose-registry.yaml \
	up -d

	@echo
	@echo "Build application image."
	docker build . \
		-t "$(FULL_IMAGE)"

	@echo
	@echo "Push image to local registry."
	docker push "$(FULL_IMAGE)"

	@echo
	@echo "Apply Deployment and Service definitions to K3s cluster."
	# kubectl --kubeconfig=./kubeconfig.yaml apply -f my-echo.yaml
	cat ./my-echo.yaml | sed "s/{{IMAGE_WITH_TAG}}/$(REPLACE_IMAGE)/g" | kubectl --kubeconfig=./kubeconfig.yaml apply -f -

	@echo
	@echo "Waiting for deployment done."
	until kubectl --kubeconfig=./kubeconfig.yaml rollout status deployment my-echo; do sleep 1; done


.PHONY: integration-down
integration-down:
	@echo
	@echo "Stop K3s cluster and registry locally."
	docker-compose \
	-f ./docker-compose.yaml \
	-f ./docker-compose-registry.yaml \
	down
