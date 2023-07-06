#!/bin/bash

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
  "./ecodata/ecodata-prod"
  "./events/events-prod-2023"
  "./fieldcapture/fieldcapture-prod"
  "./fieldguide/fieldguide-prod"
  "./image-service/image-service-prod"
  "./logger/logger-prod"
  "./namematching/namematching-prod"
  "./pdf-service/pdf-service-prod"
  "./pipelines/aws-spark-quoll-pipelines.yml"
  "./pipelines/databox-pipelines.yml"
  "./pipelines/nci3-spark-pipelines.yml"
  "./profiles/profiles-prod"
  "./regions/regions-prod"
  "./sampling/sampling-prod"
  "./sandbox/sandbox-prod"
  "./sensitive-data-service/sensitive-data-service-prod-2022"
  "./spatial/spatial-prod"
  "./specieslists/specieslists-prod"
)

optional_arg="$1"

for el in "${list[@]}"
do
  if [[ -z $optional_arg ]] || [[ $el == *"$optional_arg"* ]]; then
    echo -n "$el "
    ./do generate_custom "$el"
  fi
done
