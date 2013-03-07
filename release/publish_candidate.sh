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

EMAIL_TPL=../email/vote_release.txt

if test -n "$1"; then
    candidate_dir=$1
else
	echo "error: no candidate directory"
    exit
fi

if test -n "$2"; then
    version=$2
else
	echo "error: no version"
    exit
fi

if test -n "$3"; then
    candidate=$3
else
	echo "error: no candidate number"
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

build_file=build.mk

cat > $build_file <<EOF
# SVN_URL=https://dist.apache.org/repos/dist/dev/couchdb

SVN_URL=https://svn.apache.org/repos/asf/couchdb/site/test

TMP_DIR=$tmp_dir

SVN_DIR=\$(TMP_DIR)/svn

SVN_DOT_DIR=\$(TMP_DIR)/.svn

EMAIL_TPL=$EMAIL_TPL

EMAIL_FILE=\$(TMP_DIR)/email.txt

VERSION=$version

CANDIDATE=$candidate

CANDIDATE_DIR=$candidate_dir

CANDIDATE_URL=\$(SVN_URL)/source/\$(VERSION)/rc.\$(CANDIDATE)

PACKAGE=apache-couchdb-\$(VERSION)

CANDIDATE_TGZ_FILE=\$(CANDIDATE_DIR)/\$(PACKAGE).tar.gz

SVN_TGZ_FILE=\$(SVN_DIR)/\$(PACKAGE).tar.gz

COMMIT_MSG_DIR="Add \$(VERSION) rc.\$(CANDIDATE) dir"

COMMIT_MSG_FILES="Add \$(VERSION) rc.\$(CANDIDATE) files"

GPG=gpg --armor --detach-sig \$(GPG_ARGS)

SVN=svn --config-dir \$(SVN_DOT_DIR) --no-auth-cache

all: checkin

checkin: sign
	cd \$(SVN_DIR) && \$(SVN) add \$(SVN_TGZ_FILE)
	cd \$(SVN_DIR) && \$(SVN) add \$(SVN_TGZ_FILE).asc
	cd \$(SVN_DIR) && \$(SVN) add \$(SVN_TGZ_FILE).ish
	cd \$(SVN_DIR) && \$(SVN) add \$(SVN_TGZ_FILE).md5
	cd \$(SVN_DIR) && \$(SVN) add \$(SVN_TGZ_FILE).sha
	cd \$(SVN_DIR) && \$(SVN) status
	sleep 10
	cd \$(SVN_DIR) && \$(SVN) ci -m \$(COMMIT_MSG_FILES)

sign: copy
	\$(GPG) < \$(SVN_TGZ_FILE) > \$(SVN_TGZ_FILE).asc
	md5sum \$(SVN_TGZ_FILE) > \$(SVN_TGZ_FILE).md5
	sha1sum \$(SVN_TGZ_FILE) > \$(SVN_TGZ_FILE).sha

copy: check
	cp \$(CANDIDATE_TGZ_FILE) \$(SVN_TGZ_FILE)
	cp \$(CANDIDATE_TGZ_FILE).ish \$(SVN_TGZ_FILE).ish

check: \$(SVN_DIR)
	test -s \$(CANDIDATE_TGZ_FILE)
	test -s \$(CANDIDATE_TGZ_FILE).ish

\$(SVN_DIR): \$(SVN_DOT_DIR)
	\$(SVN) mkdir --parents \$(CANDIDATE_URL) -m \$(COMMIT_MSG_DIR)
	sleep 10
	\$(SVN) co \$(CANDIDATE_URL) \$@

\$(SVN_DOT_DIR):
	mkdir \$@

email: \$(EMAIL_FILE)

\$(EMAIL_FILE): \$(EMAIL_TPL)
	sed -e "s|%VERSION%|\$(VERSION)|g" \
	    -e "s|%CANDIDATE%|\$(CANDIDATE)|g"  \
	    -e "s|%CANDIDATE_URL%|\$(CANDIDATE_URL)|g" \
	    -e "s|%PACKAGE%|\$(PACKAGE)|g" > \
	    \$@ < \$<
EOF

log "Checking candidate into Subversion..."

make -f $build_file

log "Generating email template..."

make -f $build_file email

email_file=$tmp_dir/email.txt

echo "Email text written to:" $email_file

echo "Send the email to: dev@couchdb.apache.org"

echo "Files in: $tmp_dir"
