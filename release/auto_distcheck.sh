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

if test -n "$1"; then
    version=$1
else
    echo "error: no version"
    exit 1
fi

log () {
    printf "\033[1;31m$1\033[0m\n"
}

basename=`basename $0`

temp_dir=`mktemp -d /tmp/${basename}.XXXXXX` || exit 1

exit="echo Files in: $temp_dir"

trap "echo && $exit && kill 0" SIGINT

build () {
	time_start=`date "+%s"`
	log_file=$temp_dir/$time_start".txt"
	echo "Build started `date -r $time_start`" > $log_file
	make distcheck | tee -a $log_file
	time_finish=`date "+%s"`
	echo "Build finished `date -r $time_finish`" >> $log_file
	total_time=`expr $time_finish - $time_start`
	echo "Build took `TZ=UTC date -r $total_time +%H:%M:%S`" >> $log_file
}

while true; do
    sleep 5
    log "Checking build..."
    if test -s apache-couchdb-$version.tar.gz; then
        break
    else
        build
    fi
done

log "Build success..."

$exit

