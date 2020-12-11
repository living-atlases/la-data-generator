#!/bin/bash

set -e

CMD=$(basename $0)

IMGNAME=livingatlases/la-data-generator
CNTNAME=la-data-generator

if [[ ! -e ./docopts ]] ; then
    curl -s -o ./docopts -LJO https://github.com/docopt/docopts/releases/download/v0.6.3-rc2/docopts_linux_amd64
    chmod +x ./docopts
fi

eval "$(./docopts -V - -h - : "$@" <<EOF

$CMD: LA data generator

Usage:
  $CMD [options] build
  $CMD [options] --data=<dir> --inv=<dir> [--ala-install=<dir>] run
  $CMD [options] generate [<service>...]
  $CMD -h | --help
  $CMD -v | --version

Options:
  --verbose            Verbose output.
  -d --dry-run         Print the commands without actually running them.
  -h --help            Show this help.
  -v --version         Show version.
----
$CMD $VER
License Apache-2.0
EOF
)"

if ($dry_run); then _D=echo; else _D=; fi
if ($dry_run); then echo "Only printing the commands:"; fi

FIND_DOCKER=$(which docker)
if [[ -z $FIND_DOCKER ]]
then
    echo "ERROR: Please install docker"
    exit 1
fi

set +e
docker inspect $CNTNAME | grep "Running" >/dev/null 2>&1
if [[ $? = 0 ]]; then CONTAINER_RUNNING=1 ; else CONTAINER_RUNNING=0; fi
set -e

if $verbose; then
    echo build: $build
    echo run: $run
    echo generate: $generate
    echo data: $data
    echo inv: $inv
    echo service: $service
    echo container running: $CONTAINER_RUNNING
fi

function gen() {
    local what="$1"
    echo "Generating config for '$what'"
    if $verbose; then V="-vvvv" ; else V=""; fi
    $_D docker exec -i -t $CNTNAME bash -c "cd /ansible/la-inventories; ./ansiblew --alainstall=/ansible/ala-install $what --tags=common,augeas,tomcat,properties --skip=restart,image-stored-procedures,db -e 'skip_handlers=true' --nodryrun $V"
    if [ $? -ne 0 ]; then
      >&2 echo "The generation failed, are you inventories and/or your ala-install repo up-to-date?"
    fi
}

if [[ -n $service ]] ; then
    services=("${service[@]}")
fi

if $build ; then
    $_D docker build . -t $IMGNAME
elif $run ; then
    if [[ ! -d $data ]]; then
        >&2 echo "Directory '$data' does not exists"
        exit 1
    fi

    if [[ ! $data =~ ^/.* ]]; then
        >&2 echo "Use an /absolute path for directory '$data' "
        exit 1
    fi

    if [[ ! $inv =~ ^/.* ]]; then
        >&2 echo "Use an /absolute path for directory '$inv' "
        exit 1
    fi

    if [[ ! -d $inv || ! -f $inv/ansiblew ]]; then
        >&2 echo "It seems that '$inv' is not a generated inventory as we expect"
        exit 1
    fi

    if [[ -d $ala_install && ! -d $ala_install/ansible ]]; then
        >&2 echo "It seems that '$ala_install' is not the ala-install repository as we expect"
        exit 1
    fi

    if [[ $CONTAINER_RUNNING = 1 ]] ; then docker stop $CNTNAME; sleep 2; fi

    if [[ ! -d $ala_install ]] ; then
       $_D docker run --rm -i -v $data:/data -v $inv:/ansible/la-inventories -P -d --name $CNTNAME $IMGNAME:latest
   else
       $_D docker run --rm -i -v $data:/data -v $inv:/ansible/la-inventories -v $ala_install:/ansible/ala-install -P -d --name $CNTNAME $IMGNAME:latest
   fi
elif $generate ; then
    if [[ $CONTAINER_RUNNING = 0 ]] ; then >&2 echo "Please use 'build' and 'run' before 'generate'"; exit 1; fi
    $_D docker exec -i -t $CNTNAME bash -c "cat /ansible/la-inventories/dot-ssh-config  | sed 's/1.2.3.X/127.0.0.1/g' | sed 's/IdentityFile/#IdentityFile/g' > /root/.ssh/config.d/la"
    if [[ -n $service ]] ; then
        for s in "${services[@]}"; do
            gen "$s"
        done
    else
        gen all
    fi
fi
