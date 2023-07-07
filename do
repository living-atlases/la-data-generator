#!/bin/bash

# It will fail if some playbook fails 
set -e

CMD=$(basename $0)

IMGNAME=docker.io/livingatlases/la-data-generator
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
  $CMD [options] generate_custom <custom_inv>
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
    echo custom_inv: $custom_inv
    echo service: $service
    echo container running: $CONTAINER_RUNNING
fi


TAGS=common,augeas,properties,tomcat,mongodb-org,,namematching-service,pipelines,apt
SKIP_TAGS=restart,image-stored-procedures,db,mongodb-org-restart
EXTRAS="skip_handlers=true tomcat=tomcat8 tomcat_user=tomcat8 tomcat_apr=false biocollect_user=tomcat8 ecodata_user=tomcat8 merit_user=tomcat8 fieldguide_app=fieldguide use_docker_with_pipelines=false spark_user=root"

function gen() {
    local what="$1"
    echo "Generating config for '$what'"
    if $verbose; then V="-vvvv" ; else V=""; fi
    $_D docker exec -t $CNTNAME bash -c "cd /ansible/la-inventories; ./ansiblew --alainstall=/ansible/ala-install ansible$what --tags=$TAGS --skip=$SKIP_TAGS -e '$EXTRAS' --nodryrun $V"
    if [ $? -ne 0 ]; then
      >&2 echo "The generation failed, are you inventories and/or your ala-install repo up-to-date?"
    fi
}

function genCustom() {
    local inv="$1"
    local play="/ansible/ala-install/ansible$2"
    echo "Generating config for '$inv' and '$play'"

    if $verbose; then V="-vvvv" ; else V=""; fi
    $_D docker exec -t $CNTNAME bash -c "cd /ansible/la-inventories; ansible-playbook -u ubuntu --become -i $inv $play --tags $TAGS --skip-tags $SKIP_TAGS --extra-vars '$EXTRAS' $V"
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

    if [ -z "$(find $inv -mindepth 1 -print -quit)" ]; then
        >&2 echo "WARN: It seems that '$inv' is empty"
        exit 1
    fi

    if [[ ! -d $inv || ! -f $inv/ansiblew ]]; then
        >&2 echo "WARN: It seems that '$inv' is not a generated inventory as we expect"
        # exit 1
    fi

    if [[ -d $ala_install && ! -d $ala_install/ansible ]]; then
        >&2 echo "It seems that '$ala_install' is not the ala-install repository as we expect"
        exit 1
    fi

    if [[ $CONTAINER_RUNNING = 1 ]] ; then docker stop $CNTNAME; sleep 2; fi

    if [[ ! -d $ala_install ]] ; then
       $_D docker run --rm -t -v $data:/data:rw -v $inv:/ansible/la-inventories:rw -P -d --name $CNTNAME $IMGNAME:latest
   else
       $_D docker run --rm -t -v $data:/data:rw -v $inv:/ansible/la-inventories:rw -v $ala_install:/ansible/ala-install:rw -P -d --name $CNTNAME $IMGNAME:latest
    fi
elif $generate_custom ; then
      if [[ $CONTAINER_RUNNING = 0 ]] ; then >&2 echo "Please use 'build' and 'run' before 'generate'"; exit 1; fi

        echo "Processing /ansible/la-inventories/$custom_inv"
        set +e
        output=$($_D docker exec -t $CNTNAME bash -c "grep 'ansible-playbook -i' /ansible/la-inventories/$custom_inv 2>&1")
        set -e

        #inventory_pattern="-i"
        playbook_pattern="ala-install/ansible"

        while IFS= read -r line; do
          if [[ $line == *"ansible-playbook -i"* ]]; then

          playbook=$(awk -F "$playbook_pattern" '{print $2}' <<< "$line" | awk '{gsub(/--.*$/, ""); print}')
          playbook=${playbook// /}
        fi
        done <<< "$output"

      if [[ -z "$playbook" ]]; then
        >&2 echo "Playbook not detected in inventory comments"
        exit 1
      fi

      $_D docker exec -t $CNTNAME bash -c "echo -e 'Host *\n  Hostname 127.0.0.1\n  StrictHostKeyChecking no\n' > /root/.ssh/config.d/la"
      genCustom "$inv$custom_inv" "$playbook"
elif $generate ; then
    if [[ $CONTAINER_RUNNING = 0 ]] ; then >&2 echo "Please use 'build' and 'run' before 'generate'"; exit 1; fi
    $_D docker exec -t $CNTNAME bash -c "cat /ansible/la-inventories/dot-ssh-config  | sed 's/1.2.3.X/127.0.0.1/g' | sed 's/IdentityFile/#IdentityFile/g' > /root/.ssh/config.d/la"
    if [[ -n $service ]] ; then
        for s in "${services[@]}"; do
            gen "$s"
        done
    else
        gen all
    fi
fi
