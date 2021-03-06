#!/bin/bash
set -eux
NODES=${NODES:='None'}

RUST_TEST_THREADS=1 cargo test --all

if ! modprobe wireguard ; then
	echo "The container can't load modules into the host kernel"
	echo "Please install WireGuard https://www.wireguard.com/ and load the kernel module using 'sudo modprobe wireguard'"
	exit 1
fi

# cleanup docker junk or this script will quickly run you out of room in /
echo "Docker images take up a lot of space in root if you are running out of space select Yes"
docker system prune -a -f

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKERFOLDER=$DIR/../integration-tests/container/
REPOFOLDER=$DIR/..
tar --exclude $REPOFOLDER/target \
    --exclude $REPOFOLDER/**/target \
    --exclude $REPOFOLDER/integration-tests/althea_rs_a \
    --exclude $REPOFOLDER/integration-tests/althea_rs_b \
    --exclude $REPOFOLDER/integration-tests/target_a \
    --exclude $REPOFOLDER/integration-tests/target_b \
    --exclude $REPOFOLDER/integration-tests/deps \
    --exclude $REPOFOLDER/integration-tests/container/rita.tar.gz \
    --exclude $REPOFOLDER/scripts --dereference --hard-dereference -czf $DOCKERFOLDER/rita.tar.gz $REPOFOLDER
pushd $DOCKERFOLDER
time docker build -t rita-test --build-arg NODES=$NODES .
time docker run --privileged -it rita-test
rm rita.tar.gz
popd
