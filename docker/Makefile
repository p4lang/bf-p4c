# usage: this makefile is usually invoked from Jenkins, which also embeds
# up-to-date tags into it

# There are the following important targets:
# - builder                this builds a docker image suitable for building bf-p4c.
#                          Essentially it contains p4factory without compiler.  The remaining images
#                          build on top of this one. This image would be only build in dev-env
#                          update job.  You can overide the tag by setting BUILDER_TAG: make builder
#                          BUILDER_TAG=...
# - jarvis                 is intended for use by p4c developers it contains additional tools
#                          useful for programmers on top of what is included in builder You can
#                          overide the tag by setting JARVIS_TAG: make jarvis JARVIS_TAG=...
# - build                  an image which contains a build of bf-p4c obtained from the current
#                          working copy. This would be used in Jenkins to build to test build of the
#                          compiler.  This would be normally invoked from Jenkins to build the
#                          compiler for running of tests. The image will be tagged as
#                          $(DOCKER_PROJECT)/bf-p4c-compilers:$(BUILD_TAG), where $(BUILD_TAG)
#                          defaults to $(GIT_BRANCH) but would be often set explicitly.
# - test-build             similar to 'build', but does not produce a final image, only builds the
#                          compiler and then discards the results. This would be used for example to
#                          test non-standard builds that are not used later in the pipeline.
# - build-internal-cached  is intended only for CI use, it caches an image with a copy of the
#                          compiler repo to be used in multiple builds
# - show-builder-tag       just print the identification of the builder image

# This should be done first -- get path to self (for update)
SELF = $(lastword $(MAKEFILE_LIST))

# these variables are set by dev-env update script
# p4factory git commit to use
P4FACTORY_GIT_REV ?= f5ef0ded4aaa0e5c5c2ab2fd350a717617ed21e8
# builder image to use
BUILDER_IMAGE ?= bf-p4c-builder@sha256:d114e9f3913ad3d1dddd2202a44ab22dcfc1c58b860ac0285c8a1805f943e6e2
# end of update variables


# the defaults in the following variables would probably not need to be changed except for testing
DOCKER ?= docker
BUILDING_IN_CI ?= "false"
# get default from git
GIT_REV_ != git rev-parse HEAD
GIT_REV ?= $(GIT_REV_)
GIT_BRANCH_ != git rev-parse --abbrev-ref HEAD
GIT_BRANCH ?= $(GIT_BRANCH_)
# Intel CaaS (AMR)
DOCKER_PROJECT ?= amr-registry.caas.intel.com/bxd-sw
P4FACTORY_PROJECT ?= artifacts-bxdsw.sc.intel.com:9444/dependencies
P4FACTORY_BRANCH ?= master
# p4factory base docker image to use (ubuntu-20.04:<tag> or ubuntu-20.04@sha256:<hash>)
# it is build by all-dependencies target of Dockerfile.p4factory (in p4factory) and pushed to
# $(P4FACTORY_PROJECT)
# Normally we point this to latest build from master branch, which is pulled when doing dev-env
# update. This means it can be behing the $(P4FACTORY_GIT_REV), but that should not be a problem
# usually.
P4FACTORY_IMAGE ?= ubuntu-20.04:$(P4FACTORY_BRANCH)

BUILDER_PROJECT ?= $(DOCKER_PROJECT)
BUILDER_P4FACTORY_GIT_REV != $(DOCKER) inspect --format='{{index .Config.Labels "P4FACTORY_GIT_REV"}}' $(BUILDER_PROJECT)/$(BUILDER_IMAGE)
BUILDER_BF_P4C_GIT_REV != $(DOCKER) inspect --format='{{index .Config.Labels "BF_P4C_GIT_REV"}}' $(BUILDER_PROJECT)/$(BUILDER_IMAGE)
BUILDER_TAG ?= bf-p4c-builder
DOCKER_BUILD_JOBS_ != nproc
DOCKER_BUILD_JOBS ?= $(DOCKER_BUILD_JOBS_)
BUILD_TAG_ != echo $(GIT_BRANCH) | sed 's,/,--,g'
BUILD_TAG ?= $(BUILD_TAG_)
BUILD_TAG_DEST ?= bf-p4c-compilers

BUILD_SCRIPT ?= /bfn/bf-p4c-compilers/docker/docker_build.sh

BUILD_INTERMEDIATE_TAG ?= intermediate_build:latest
JARVIS_TAG ?= jarvis

ifeq ($(BUILDING_IN_CI), true)
CCACHE_ARG = -v ~/.ccache_bf-p4c-compilers:/root/.ccache
else
CCACHE_ARG =
endif

builder :
	cd .. && $(DOCKER) build \
	    --build-arg DOCKER_PROJECT=$(DOCKER_PROJECT) \
	    --build-arg P4FACTORY_PROJECT=$(P4FACTORY_PROJECT) \
	    --build-arg P4FACTORY_IMAGE=$(P4FACTORY_IMAGE) \
	    --build-arg P4FACTORY_GIT_REV=$(P4FACTORY_GIT_REV) \
	    --build-arg BUILDING_IN_CI=$(BUILDING_IN_CI) \
	    --build-arg GIT_REV=$(GIT_REV) \
	    --build-arg BUILD_JOBS=$(DOCKER_BUILD_JOBS) \
	    --target=builder \
	    -t $(BUILDER_TAG) \
	    -f docker/Dockerfile.builder .

jarvis :
	cd .. && $(DOCKER) build -t $(JARVIS_TAG) \
	    --build-arg BASE_IMAGE=$(BUILDER_PROJECT)/$(BUILDER_IMAGE) \
	    --build-arg P4FACTORY_GIT_REV=$(BUILDER_P4FACTORY_GIT_REV) \
	    --build-arg GIT_REV=$(BUILDER_BF_P4C_GIT_REV) \
	    -f docker/Dockerfile.jarvis .

build-internal-cached : build-inter.$(GIT_REV)
	touch $<

build-inter.$(GIT_REV) :
	if [ "$(BUILDING_IN_CI)" = "true" ]; then mkdir -p ~/.ccache_bf-p4c-compilers; fi
	-$(DOCKER) rm -f $(BUILD_INTERMEDIATE_TAG) 2> /dev/null
	cd .. && $(DOCKER) build -t $(BUILD_INTERMEDIATE_TAG) \
	    --build-arg BASE_IMAGE=$(BUILDER_PROJECT)/$(BUILDER_IMAGE) \
	    --build-arg GIT_REV=$(GIT_REV) \
	    -f docker/Dockerfile.build .

test-build : build-inter.$(GIT_REV)
	$(DOCKER) run \
	    $(CCACHE_ARG) \
	    --rm \
	    $(BUILD_ARGS) \
	    $(BUILD_INTERMEDIATE_TAG) \
	    $(BUILD_SCRIPT)

build : build-inter.$(GIT_REV)
	-$(DOCKER) rm -f bf-p4c-compilers_build_$(BUILD_TAG)
	$(DOCKER) run \
	    $(CCACHE_ARG) \
	    --name bf-p4c-compilers_build_$(BUILD_TAG) \
	    $(BUILD_ARGS) \
	    $(BUILD_INTERMEDIATE_TAG) \
	    $(BUILD_SCRIPT)
	$(DOCKER) commit \
		--change 'CMD ["/bin/bash"]' \
		bf-p4c-compilers_build_$(BUILD_TAG) \
		$(if $(BUILD_TAG_DEST),$(BUILD_TAG_DEST):,)$(BUILD_TAG)
	-$(DOCKER) rm -f bf-p4c-compilers_build_$(BUILD_TAG)

update :
	./do_update.sh $(SELF) $(P4FACTORY_BRANCH) $(GIT_BRANCH) $(P4FACTORY_UPDATE_REV)

clean :
	-$(DOCKER) rmi -f $(BUILDER_TAG)
	-$(DOCKER) rmi -f $(BUILD_INTERMEDIATE_TAG)
	-$(DOCKER) rm -f bf-p4c-compilers_build_$(BUILD_TAG)
	-$(DOCKER) rmi -f $(if $(BUILD_TAG_DEST),$(BUILD_TAG_DEST):,)$(BUILD_TAG)

show-builder-tag :
	@echo $(BUILDER_PROJECT)/$(BUILDER_IMAGE)

.PHONY : builder build-inter build test-build build-commit jarvis update show-builder-tag clean
