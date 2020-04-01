SHELL := bash

.SHELLFLAGS := -eu -o pipefail -c  

include .env
export

NO_COLOR		:= \x1b[0m
OK_COLOR		:= \x1b[32;01m
ERROR_COLOR	:= \x1b[31;01m
WARN_COLOR	:= \x1b[33;01m

# =================================================================
# = Utility targets ===============================================
# =================================================================

# =================================================================
# Allows a target to require environment variables to exist
# Example that will only run 'mytarget' when the environment variable named 'SERVER' has been set:
#  mytarget: env-SERVER another-dependency
# =================================================================
env-%:
	@if [ "${${*}}" = "" ]; then \
		echo "Required environment variable $* not set"; \
		echo; \
		exit 1; \
	fi

clean:
	@echo
	@echo Cleaning up
	@rm -rf build node_modules


# =================================================================
# = Build targets =================================================
# =================================================================

docker-build: env-CONTAINER_IMAGE_TAG env-REACT_APP_OKTA_URL env-REACT_APP_CLIENT_ID env-REACT_APP_URQL_URL
	@printf "$(OK_COLOR)"																																												&& \
	 printf "\n%s\n" "======================================================================================"		&& \
	 printf "%s\n"   "= Building container image: ${CONTAINER_IMAGE_TAG}"																				&& \
	 printf "%s\n"   "======================================================================================"		&& \
	 printf "$(NO_COLOR)"																																												&& \
	 docker build																								\
	 	-t ${CONTAINER_IMAGE_TAG}																	\
	 	--build-arg REACT_APP_OKTA_URL=${REACT_APP_OKTA_URL}			\
		--build-arg REACT_APP_CLIENT_ID=${REACT_APP_CLIENT_ID}		\
		--build-arg REACT_APP_URQL_URL=${REACT_APP_URQL_URL}			\
		.

docker-push: env-CONTAINER_IMAGE_TAG docker-build
	@printf "$(OK_COLOR)"																																												&& \
	 printf "\n%s\n" "======================================================================================"		&& \
	 printf "%s\n"   "= Pushing container image: ${CONTAINER_IMAGE_TAG}"			  																&& \
	 printf "%s\n"   "======================================================================================"		&& \
	 printf "$(NO_COLOR)"																																												&& \
	 docker push ${CONTAINER_IMAGE_TAG}

docker-run: env-CONTAINER_IMAGE_TAG docker-build
	@printf "$(OK_COLOR)"																																												&& \
	 printf "\n%s\n" "======================================================================================"		&& \
	 printf "%s\n"   "= Running container image: ${CONTAINER_IMAGE_TAG}"			  																&& \
	 printf "%s\n"   "======================================================================================"		&& \
	 printf "$(NO_COLOR)"																																												&& \
	 docker run -p 8000:8000 --env-file .env ${CONTAINER_IMAGE_TAG}

docker-shell: env-CONTAINER_IMAGE_TAG docker-build
	@printf "$(OK_COLOR)"																																												&& \
	 printf "\n%s\n" "======================================================================================"		&& \
	 printf "%s\n"   "= Running container image: ${CONTAINER_IMAGE_TAG}"			  																&& \
	 printf "%s\n"   "======================================================================================"		&& \
	 printf "$(NO_COLOR)"																																												&& \
	 docker run -it --rm ${CONTAINER_IMAGE_TAG} /bin/ash

