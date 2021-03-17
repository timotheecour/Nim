# Container image that runs your code
FROM alpine:3.10

# Copies your code file from your action repository to the filesystem path `/` of the container
# COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
# ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["sh build_all.sh"]
# CMD "pwd && ls && sh build_all.sh"
# ENTRYPOINT pwd && ls && sh build_all.sh
ENTRYPOINT sh ci/dockerrun.sh

