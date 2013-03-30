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
    exit
fi

if test -n "$2"; then
    candidate=$2
else
    echo "error: no candidate number"
    exit
fi

if test -n "$3"; then
    gpg_key=$3
else
    echo "error: no GPG key"
    exit
fi

log () {
    printf "\033[1;31m$1\033[0m\n"
}

cd `dirname $0`

basename=`basename $0`

log "Creating temporary directory..."

tmp_dir=`mktemp -d /tmp/$basename.XXXXXX` || exit 1

echo $tmp_dir

build_file=$tmp_dir/build.mk

cat > $build_file <<EOF
GIR_URL=https://git-wip-us.apache.org/repos/asf/couchdb.git

SVN_DEV_URL=https://dist.apache.org/repos/dist/dev/couchdb

SVN_RELEASE_URL=https://dist.apache.org/repos/dist/release/couchdb

TMP_DIR=$tmp_dir

GIT_DIR=\$(TMP_DIR)/git

RC_FILE=\$(TMP_DIR)/rc.txt

ISH_FILE=\$(TMP_DIR)/ish.txt

VERSION=$version

CANDIDATE=$candidate

GPG_KEY=$gpg_key

PACKAGE=apache-couchdb-\$(VERSION)

VERSION_DEV_URL=\$(SVN_DEV_URL)/source/\$(VERSION)

VERSION_RELEASE_URL=\$(SVN_RELEASE_URL)/source/\$(VERSION)

CANDIDATE_DEV_URL=\$(VERSION_DEV_URL)/rc.\$(CANDIDATE)

CANDIDATE_ISH_DEV_URL=\$(CANDIDATE_DEV_URL)/\$(PACKAGE).tar.gz.ish

COMMIT_MSG_TAG="Apache CouchDB \$(VERSION)"

COMMIT_MSG_DIR="Copy \$(VERSION) source dir"

all:

release:
	svn cp \$(CANDIDATE_DEV_URL) \$(VERSION_RELEASE_URL) \
	    -m \$(COMMIT_MSG_DIR)
	echo "Release dist directory: \$(VERSION_RELEASE_URL)"

tag: \$(GIT_DIR)
	git tag -u \$(GPG_KEY) \$(VERSION) \
	    \`cat \$(ISH_FILE)\` -m \$(COMMIT_MSG_TAG)
	git push origin \$(VERSION)

\$(GIT_DIR): check
	git clone \$(GIR_URL) \$@

check: \$(ISH_FILE)
	test "\`cat \$(RC_FILE)\`" = "rc.\$(CANDIDATE)/"
	svn info \$(VERSION_RELEASE_URL) > /dev/null 2>&1; \
	    test "\$\$?" -eq 1

\$(ISH_FILE): \$(RC_FILE)
	svn cat \$(CANDIDATE_ISH_DEV_URL) > \$@

\$(RC_FILE): \$(SVN_DOT_DIR)
	svn ls \$(VERSION_DEV_URL) | sort -r | head -n 1 > \$@
EOF

log "Tagging candidate..."

make -f $build_file tag

log "Copying candidate to the release dist directory..."

make -f $build_file release

echo "Files in: $tmp_dir"
