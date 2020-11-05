#!/bin/bash

set -e

CMD=$(basename $0)

IMGNAME=la-data-generator

if [[ ! -e ./docopts ]] ; then
    curl -s -o ./docopts -LJO https://github.com/docopt/docopts/releases/download/v0.6.3-rc2/docopts_linux_amd64
    chmod +x ./docopts
fi

eval "$(./docopts -V - -h - : "$@" <<EOF

$CMD: LA data generator

Usage:
  $CMD [options] build
  $CMD [options] --data=<dir> --inv=<dir> [--ala-install=<dir>] run
  $CMD [options] generate
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


# TODO test that docker is installed

# TEST other dirs

if ($dry_run); then _D=echo; else _D=; fi
if ($dry_run); then echo "Only printing the commands:"; fi

if $verbose; then
   echo build: $build
   echo run: $run
   echo data: $data
   echo inv: $inv
fi

#docker inspect $IMGNAME | grep "Running"

if $build ; then
    $_D docker build . -t $IMGNAME
elif $run ; then
    if [[ ! -d $data ]]; then
        >&2 echo "Directory '$data' does not exists"
        exit 1
    fi

    # TODO data should be abssolute

    if [[ ! -d $inv || ! -f $inv/ansiblew ]]; then
        >&2 echo "It seems that '$inv' is not a generated inventory as we expect"
        exit 1
    fi

    if [[ -d $ala_install && ! -d $ala_install/ansible ]]; then
        >&2 echo "It seems that '$ala_install' is not the ala-install repository as we expect"
        exit 1
    fi

    # TODO test if the container is still running

    if [[ ! -d $ala_install ]] ; then
       $_D docker run --rm -it -v $data:/data -v $inv:/ansible/la-inventories -P -d --name $IMGNAME $IMGNAME:latest
   else
       $_D docker run --rm -it -v $data:/data -v $inv:/ansible/la-inventories -v $ala_install:/ansible/ala-install -P -d --name $IMGNAME $IMGNAME:latest
   fi
elif $generate ; then
    # Verify the container is running
    $_D docker exec -i -t $IMGNAME bash -c "cat /ansible/la-inventories/dot-ssh-config  | sed 's/1.2.3.X/127.0.0.1/g' | sed 's/IdentityFile/#IdentityFile/g' > /root/.ssh/config.d/la"
    $_D docker exec -i -t $IMGNAME bash -c 'cd /ansible/la-inventories; ./ansiblew --alainstall=/ansible/ala-install all --tags=common,augeas,tomcat,properties --skip=restart,image-stored-procedures --nodryrun'
fi
