## Introduction

Many times we need some LA configurations, those generated by [ala-install](https://github.com/AtlasOfLivingAustralia/ala-install/) typically in `/data` when using `ansible` to deploy a LA portal.

These configurations are useful for instance:
- To setup a [LA Development environment](https://github.com/AtlasOfLivingAustralia/documentation/wiki/LA-Development-Guide#development-configuration).
- On docker LA deployments that don't use `ala-install`.

More than these configurations, it's also important to have a correct directory hierarchy, users/groups and permissions of this `/data` directory and descendants.

So many times people ask in our slack channel for these configurations, or ask for the permissions of some of these directories.

This helper generate this `/data` for you, using `docker` + `ala-install` + some-inventories and some basic steps.

## 1) Prerequisites

### This repo

Clone or download this repository and follow these steps:

### Some inventories

You will need some LA generated `ansible` inventories, use the [command line](https://github.com/living-atlases/generator-living-atlas/) or the web interface: [https://generator.l-a.site](https://generator.l-a.site).

Setup a `LA_INV` enviroment shell variable pointing to the directory of these inventories:

```bash
export LA_INV=/home/myuser/the/directory/where/I/unziped/the/inventories
```

### Some `data` directory 

If you need some development environment, create a `/data` owned by you:

```bash
sudo mkdir /data
sudo chown youruser:youruser /data
export DATA_DIR=/data/
```

or if you don't need it for a develoment environment, you can create a data directory in any other location:

```bash
mkdir /tmp/data
export DATA_DIR=/tmp/data/
```

We'll use this `DATA_DIR` as a volume in the docker image.

### docker

As we mentioned above, we use `docker` to run `ansible` inside a container and generate that LA `/data` for you. 

So you need to [install docker](https://docs.docker.com/engine/install/) in the computer you are using.

### Optionally the `ala-install` repository

You can provide an `ala-install` cloned repository as a docker volume, or if not, we'll use a stable version for you.

Let's setup this in a variable also:

```bash
export ALA_INSTALL=/home/myuser/ala-install-location/
```

## 2) Build

Now you can build this image:

```bash
./do build 
```
## Or directly pull it from docker hub

```bash
docker pull livingatlases/la-data-generator
```

## 3) Run

### Run the image with stable `ala-install` 

```bash
./do --data=$DATA_DIR --inv=$LA_INV run

```
 
### Or run the image with some other `ala-install` 

Clone `ala-install` in some directory and run this image with that `ala-install` volume.

```bash
./do --data=$DATA_DIR --inv=$LA_INV --ala-install=$AL_INSTALL run
```

### 4) Finally, generate all `/data` in `DATA_DIR`

```bash
./do generate
```
or just some service:

```bash
./do generate spatial
```

In the previous step we configured the `ssh` to fake a bit your inventories hostnames, so ansible will access via `ssh` to localhost and configure the `DATA_DIR` volume.

At the end your configs will be accesible in:

```bash
ls -l $DATA_DIR
```

Check the `uid`/`gid` of each user with:

```bash
docker exec -i -t la-data-generator bash -c 'id tomcat7; id solr; id image-service; id postgres; id doi-service'
```
## Re-run

You can edit your inventories to fit better to your needs, [update the inventories](https://github.com/living-atlases/generator-living-atlas#rerunning-the-generator), and rerun the previous `ansiblew` docker exec command to update your `DATA_DIR`.

## Stop and remove the container 

```bash
docker stop la-data-generator
```
## Sample `DATA_DIR` output

![](data.png)

## Further help

```
$ ./do -h
do: LA data generator

Usage:
  do [options] build
  do [options] --data=<dir> --inv=<dir> [--ala-install=<dir>] run
  do [options] generate [<service>...]
  do -h | --help
  do -v | --version

Options:
  --verbose            Verbose output.
  -d --dry-run         Print the commands without actually running them.
  -h --help            Show this help.
  -v --version         Show version.

```

## License

Apache-2.0 © [Living Atlases](https://living-atlases.gbif.org)
