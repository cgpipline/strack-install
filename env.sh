#!/bin/bash

# check if docker and docker-compose available

type docker 2>&1 >/dev/null ||
{
    printf "\x1b[31;1mError\x1b[0m: docker cli tool was not found, check if docker installed \n"
    exit 1
}

[ "`docker -v | grep -E '^podman'`x" = "x" ] ||
{
    printf "\x1b[1mWaring\x1b[0m: podman support is not proved, use it with caution!\n"
}

docker info 2>&1 >/dev/null ||
{
    printf "\x1b[31;1mError\x1b[0m: \`docker info\` command failed, this meaning docker is not avaliable,\n\tcheck docker installation and if docker daemon running.\n"
    exit 1
}

type docker-compose 2>&1 >/dev/null ||
{
    printf "\x1b[31;1mError\x1b[0m: docker-compose was not found, check if docker-compose installed \n"
    exit 1
}

docker-compose -v 2>&1 >/dev/null ||
{
    printf "\x1b[31;1mError\x1b[0m: \`docker-compose -v\` command failed, this meaning docker-compose is not avaliable,\n\tcheck docker-compose installation and if docker daemon running.\n"
    exit 1
}
