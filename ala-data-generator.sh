#!/bin/bash

#
# Build as says in the README and run first:
# ./do build
# ./do --data=/home/youruser/dev/la-data-generator/data --inv=/home/youruser/dev/ala/ansible-inventories/ --ala-install=/home/youruser/dev/ala-install run
# and then run:
# ./ala-data-generator.sh 
# or for some specific service:
#./ala-data-generator.sh biocache

set -e

list=(
  "./alerts/alerts-prod"
  "./auth/aws-auth-prod.yml"
  "./bie/bie-hub-prod-2022"
  "./bie/bie-ws-solr-prod-2022"
  "./biocache/biocache-hub-2021"
  "./biocache/biocache-service-2021"
  "./biocache/cassandra-cluster-2021"
  "./biocache/solrcloud-2021-1"
  "./biocollect/biocollect-prod"
  "./calendars/calendars-prod"
  "./collections/collections-prod"
  "./dashboard/dashboard-prod"
  "./data_quality_filter_service/data_quality_filter_service_prod"
  "./doi/doi-prod"
  "./events/events-prod-2023"
  "./fieldcapture/fieldcapture-prod"
  "./image-service/image-service-prod"
  "./logger/logger-prod"
  "./namematching/namematching-prod"
  "./pdf-service/pdf-service-prod"
  "./profiles/profiles-prod"
  "./regions/regions-prod"
  "./sampling/sampling-prod"
  "./sandbox/sandbox-prod"
  "./sensitive-data-service/sensitive-data-service-prod-2022"
  "./spatial/spatial-prod"
  "./specieslists/specieslists-prod"
  "./pipelines/databox-pipelines.yml"
  "./ecodata/ecodata-prod"
  "./fieldguide/fieldguide-prod"
)
  #"./pipelines/aws-spark-quoll-pipelines.yml"
  #"./pipelines/nci3-spark-pipelines.yml"

optional_args=("$@")

for el in "${list[@]}"
do
  match=false
  for arg in "${optional_args[@]}"
  do
    if [[ $el == *"$arg"* ]]; then
      match=true
      break
    fi
  done

  if [[ -z "${optional_args[*]}" ]] || $match; then
    # echo -n "$el "
    ./do generate_custom "$el"
  fi
done

