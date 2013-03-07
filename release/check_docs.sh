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
    cve_list_file=$1
else
	echo "error: no remote CVE list file"
    exit 1
fi

log () {
    printf "\033[1;31m$1\033[0m\n"
}

cd `dirname $0`

basename=`basename $0`

if test -n "$2"; then
    tmp_dir=$2
else
    log "Creating temporary directory..."
    tmp_dir=`mktemp -d /tmp/$basename.XXXXXX` || exit 1
    echo $tmp_dir
fi

log "Fetching CVE list file..."

if test ! -f $tmp_dir/cve_list.txt; then
    scp people.apache.org:$cve_list_file $tmp_dir/cve_list.txt
fi

log "Cloning or fetching Git repository..."

if test ! -d $tmp_dir/git/.git; then
    git clone https://git-wip-us.apache.org/repos/asf/couchdb.git $tmp_dir/git
    cd $tmp_dir/git
else
    cd $tmp_dir/git
    git fetch
fi

rm -rf $tmp_dir/branch

branches=`git branch -r | grep -E 'origin/[0-9]+\.[0-9]+\.x$'`" master"

for branch in $branches; do
    version=`echo $branch | sed 's,origin/,,'`
    dir=$tmp_dir/branch/$version
    mkdir -p $dir
    git cat-file blob $branch:NEWS > $dir/NEWS
    git cat-file blob $branch:CHANGES > $dir/CHANGES
done

python > $tmp_dir/versions.txt << EOF
import re

versions="""
`ls $tmp_dir/branch`
""".split()

def num(s):
    try:
        return int(s)
    except:
        return s

versions.sort(key=lambda i: [num(i) for i in re.split("([0-9]+)", i)])

for version in versions:
    print version
EOF

log "Checking CVEs in NEWS..."

cat $tmp_dir/cve_list.txt | while read cve; do
    exists=`grep -r $cve $tmp_dir/branch/*/NEWS || true`
    if test ! -n "$exists"; then
        echo $cve "(missing)"
    fi
done

log "Checking CVEs in CHANGES..."

cat $tmp_dir/cve_list.txt | while read cve; do
    exists=`grep -r $cve $tmp_dir/branch/*/CHANGES || true`
    if test ! -n "$exists"; then
        echo $cve "(missing)"
    fi
done

function compare () {
    log "Comparing NEWS, $1 to $2..."
    diff $tmp_dir/branch/$1/NEWS $tmp_dir/branch/$2/NEWS | \
        grep -E "^< [^#]" || true
    log "Comparing CHANGES, $1 to $2..."
    diff $tmp_dir/branch/$1/CHANGES $tmp_dir/branch/$2/CHANGES | \
        grep -E "^< [^#]" || true
}

function scan () {
    log "Scanning $1..."
    grep "released" $tmp_dir/branch/$1/NEWS || true
    grep "released" $tmp_dir/branch/$1/CHANGES || true
}

versions=`cat $tmp_dir/versions.txt`

last_version=""

for version in $versions; do
    if test -n "$last_version"; then
        compare $last_version $version
    fi
    last_version=$version
done

for version in $versions; do
    scan $version
done
