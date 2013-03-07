#!/bin/sh -e

# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

# This script is for use by committers.
#
# It should be used in accordance with the project release procedure.
#
# cf. http://wiki.apache.org/couchdb/Release_Procedure

if test -n "$1"; then
    identity_file=$1
else
	echo "error: no identity file"
    exit 1
fi

if test -n "$2"; then
    connection=$2
else
	echo "error: no connection string"
    exit 1
fi

if test -n "$3"; then
    branch=$3
else
	echo "error: no branch"
    exit 1
fi

if test -n "$4"; then
    version=$4
else
	echo "error: no version"
    exit 1
fi

log () {
    printf "\033[1;31m$1\033[0m\n"
}

cd `dirname $0`

basename=`basename $0`

log "Creating temporary directory..."

tmp_dir=`mktemp -d /tmp/$basename.XXXXXX` || exit 1

echo $tmp_dir

log "Building candidate on remote host..."

ssh -i $identity_file $connection "sh -e" <<EOF
sudo apt-get update

sudo apt-get install -y \
    git \
    libtool \
    automake \
    autoconf \
    autoconf-archive \
    pkg-config \
    help2man \
    python-sphinx \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texinfo \
    build-essential \
    erlang-base-hipe \
    erlang-dev \
    erlang-manpages \
    erlang-eunit \
    erlang-nox \
    libicu-dev \
    libmozjs-dev \
    libcurl4-openssl-dev

rm -rf couchdb-pmc

git clone https://github.com/nslater-asf/couchdb-pmc.git

tmp_dir=\`mktemp -d /tmp/$basename.XXXXXX\` || exit 1

./couchdb-pmc/release/build_candidate.sh $branch $version \$tmp_dir

echo \$tmp_dir > ~/tmp_dir.txt
EOF

log "Fetching candidate from remote host..."

remote_tmp_dir=`ssh -i $identity_file $connection "cat ~/tmp_dir.txt"`

tgz_file=$remote_tmp_dir/apache-couchdb-$version.tar.gz

ish_file=$remote_tmp_dir/apache-couchdb-$version.tar.gz.ish

scp -i $identity_file $connection:$tgz_file $tmp_dir

scp -i $identity_file $connection:$ish_file $tmp_dir

echo "Files in: $tmp_dir"
