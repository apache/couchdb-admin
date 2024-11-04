#!/bin/sh -ex

# https://cwiki.apache.org/confluence/display/COUCHDB/Testing+a+Source+Release

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

if test -n "$1"; then
    version=$1
else
    echo "error: no version"
    exit
fi

if test -n "$2"; then
    candidate=$2
else
    echo "error: no candidate number"
    exit
fi

log () {
    printf "\033[1;31m$1\033[0m\n"
}

cd `dirname $0`

basename=`basename $0`

if test -n "$3"; then
    tmp_dir=$3
else
    tmp_dir=`mktemp -d /tmp/$basename.XXXXXX` || exit 1
    log "Creating temporary directory $tmp_dir"
fi

config_opts=${CONFIG_OPTS:-"--js-engine=quickjs --with-clouseau"}

artifact_url=https://dist.apache.org/repos/dist/dev/couchdb/source/$version/rc$candidate/

mkdir -p $tmp_dir/dist
cd $tmp_dir/dist

erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell
elixir --version
python --version
java -version

wget --no-parent --no-directories -r $artifact_url

gpg --verify apache-couchdb-*.tar.gz.asc

sha256sum --check apache-couchdb-*.tar.gz.sha256

tar -xvzf apache-couchdb-*.tar.gz

cd apache-couchdb-$version

./configure $config_opts

make check

make release

echo 'adm = pass' >>  rel/couchdb/etc/local.ini

./rel/couchdb/bin/couchdb &
dbpid=$!

dburl=http://127.0.0.1:5984

# stop the annoying errors
until curl -u adm:pass $dburl/_users -X PUT; do 
    sleep 5
done

open $dburl/_utils/

log "kill $dbpid to stop CouchDB"
