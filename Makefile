# SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>
# SPDX-FileCopyrightText: 2019-present Rimedo Labs
#
# SPDX-License-Identifier: Apache-2.0

.PHONY: build
#GO111MODULE=on 

TARGET := rimedo-ts
TARGET_TEST := rimedo-ts-test
DOCKER_TAG ?= latest

build:
	GOPRIVATE="github.com/onosproject/*" go build -o build/_output/${TARGET} ./cmd/${TARGET}

build-tools:=$(shell if [ ! -d "./build/build-tools" ]; then cd build && git clone https://github.com/onosproject/build-tools.git; fi)
include ./build/build-tools/make/onf-common.mk

docker:
	@go mod vendor
	sudo docker build --network host -f build/Dockerfile -t ${DOCKER_REPOSITORY}${TARGET}:${DOCKER_TAG} .
	@rm -rf vendor

images: build
	@go mod vendor
	docker build -f build/Dockerfile -t ${DOCKER_REPOSITORY}${TARGET}:${DOCKER_TAG} .
	@rm -rf vendor

kind: images
	@if [ "`kind get clusters`" = '' ]; then echo "no kind cluster found" && exit 1; fi
	kind load docker-image ${DOCKER_REPOSITORY}${TARGET}:${DOCKER_TAG}

helmit-ts: integration-test-namespace # @HELP run PCI tests locally
	helmit test -n test ./cmd/${TARGET_TEST} --timeout 30m --no-teardown \
			--suite ts

integration-tests: helmit-ts

test: build license
jenkins-test: build license

docker-push:
	docker push ${DOCKER_REPOSITORY}${TARGET}:${DOCKER_TAG}

publish: # @HELP publish version on github and dockerhub
	./build/build-tools/publish-version ${VERSION} onosproject/$(XAPPNAME)

jenkins-publish: jenkins-tools images docker-push-latest # @HELP Jenkins calls this to publish artifacts
	./build/build-tools/release-merge-commit


