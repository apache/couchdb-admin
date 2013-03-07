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
    branch=$1
else
	echo "error: no branch"
    exit 1
fi

if test -n "$2"; then
    version=$2
else
	echo "error: no version"
    exit 1
fi

log () {
    printf "\033[1;31m$1\033[0m\n"
}

cd `dirname $0`

basename=`basename $0`

if test -n "$3"; then
    tmp_dir=$3
else
    log "Creating temporary directory..."
    tmp_dir=`mktemp -d /tmp/$basename.XXXXXX` || exit 1
    echo $tmp_dir
fi

diff_file=$tmp_dir/diff.txt

cat > $diff_file <<EOF
^Only in $tmp_dir/1.3.x: .gitignore\$
^Only in $tmp_dir/1.3.x: .mailmap\$
^Only in $tmp_dir/1.3.x: .travis.yml\$
^Only in $tmp_dir/1.3.x: acinclude.m4.in\$
^Only in $tmp_dir/1.3.x: bootstrap\$
^Only in $tmp_dir/1.3.x: THANKS.in\$
^Only in $tmp_dir/apache-couchdb-1.3.0: acinclude.m4\$
^Only in $tmp_dir/apache-couchdb-1.3.0: aclocal.m4\$
^Only in $tmp_dir/apache-couchdb-1.3.0: config.h.in\$
^Only in $tmp_dir/apache-couchdb-1.3.0: configure\$
^Only in $tmp_dir/apache-couchdb-1.3.0: INSTALL\$
^Only in $tmp_dir/apache-couchdb-1.3.0: m4\$
^Only in $tmp_dir/apache-couchdb-1.3.0: Makefile.in\$
^Only in $tmp_dir/apache-couchdb-1.3.0: THANKS\$
^Only in $tmp_dir/apache-couchdb-1.3.0/.*: Makefile.in\$
^Only in $tmp_dir/apache-couchdb-1.3.0/bin: couchdb.1\$
^Only in $tmp_dir/apache-couchdb-1.3.0/build-aux: config.guess\$
^Only in $tmp_dir/apache-couchdb-1.3.0/build-aux: config.sub\$
^Only in $tmp_dir/apache-couchdb-1.3.0/build-aux: depcomp\$
^Only in $tmp_dir/apache-couchdb-1.3.0/build-aux: install-sh\$
^Only in $tmp_dir/apache-couchdb-1.3.0/build-aux: ltmain.sh\$
^Only in $tmp_dir/apache-couchdb-1.3.0/build-aux: missing\$
^Only in $tmp_dir/apache-couchdb-1.3.0/share/doc/build: html\$
^Only in $tmp_dir/apache-couchdb-1.3.0/share/doc/build: latex\$
^Only in $tmp_dir/apache-couchdb-1.3.0/share/doc/build: texinfo\$
^Only in $tmp_dir/apache-couchdb-1.3.0/src/couchdb/priv: couchjs.1\$
EOF

build_file=$tmp_dir/build.mk

cat > $build_file <<EOF
URL=https://git-wip-us.apache.org/repos/asf/couchdb.git

TMP_DIR=$tmp_dir

SRC_DIR=\$(TMP_DIR)/git

DIFF_FILE=$diff_file

BRANCH=$branch

VERSION=$version

PACKAGE=apache-couchdb-\$(VERSION)

SRC_FILE=\$(SRC_DIR)/\$(PACKAGE).tar.gz

TGZ_FILE=\$(TMP_DIR)/\$(PACKAGE).tar.gz

all: \$(TMP_DIR)/\$(PACKAGE).tar.gz

\$(TMP_DIR)/\$(PACKAGE).tar.gz: \$(TGZ_FILE).ish
	cd \$(SRC_DIR) && \
	    ./bootstrap
	cd \$(SRC_DIR) && \
	    ./configure --enable-strictness --disable-tests
	cd \$(SRC_DIR) && \
	    DISTCHECK_CONFIGURE_FLAGS="--disable-tests" make -j distcheck
	mv \$(SRC_FILE) \$(TGZ_FILE)

\$(TGZ_FILE).ish: \$(SRC_DIR)
	cd \$(SRC_DIR) && git show HEAD | head -n 1 | cut -d " " -f 2 > \$@

\$(SRC_DIR): \$(TMP_DIR)
	git clone \$(URL) \$@
	cd \$(SRC_DIR) && git checkout -b \$(BRANCH) origin/\$(BRANCH)

\$(TMP_DIR):
	mkdir \$@

check: check-files

check-files: check-diff
	cd \$(TMP_DIR)/\$(PACKAGE) && \
	    grep "not released" NEWS CHANGES; test "\$\$?" -eq 1
	cd \$(TMP_DIR)/\$(PACKAGE) && \
	    grep "build" acinclude.m4; test "\$\$?" -eq 1
	cd \$(TMP_DIR)/\$(PACKAGE) && \
	    grep `date +%Y` NOTICE
	cd \$(TMP_DIR)/\$(PACKAGE) && \
	    grep `date +%Y` share/doc/src/conf.py

check-diff: check-file-size
	cd \$(SRC_DIR) && git archive \
	    --prefix=\$(BRANCH)/ -o ../\$(BRANCH).tar \
	    \`cat \$(TGZ_FILE).ish\`
	cd \$(TMP_DIR) && tar -xf \$(TMP_DIR)/\$(BRANCH).tar
	cd \$(TMP_DIR) && tar -xzf \$(TGZ_FILE)
	diff -r \$(TMP_DIR)/\$(PACKAGE) \$(TMP_DIR)/\$(BRANCH) \
	    | grep --include= -vEf \$(DIFF_FILE); \
	test "\$\$?" -eq 1

check-file-size:
	test -s \$(TGZ_FILE)
	test -s \$(TGZ_FILE).ish
EOF

log_file=$tmp_dir/log.txt

echo "Build started `date`" > $log_file

log "Executing build instructions..."

make -f $build_file | tee -a $log_file

time_finish=`date "+%s"`

echo "Build finished `date`" >> $log_file

log "Checking build..."

make -f $build_file check

log "Check complete..."

echo "Files in: $tmp_dir"
