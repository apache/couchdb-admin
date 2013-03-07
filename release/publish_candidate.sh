#!/bin/sh -e

EMAIL_TPL=email/vote_release.txt

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

all: checkin

checkin: sign
	cd \$(SVN_DIR) && svn add \$(SVN_TGZ_FILE)
	cd \$(SVN_DIR) && svn add \$(SVN_TGZ_FILE).asc
	cd \$(SVN_DIR) && svn add \$(SVN_TGZ_FILE).ish
	cd \$(SVN_DIR) && svn add \$(SVN_TGZ_FILE).md5
	cd \$(SVN_DIR) && svn add \$(SVN_TGZ_FILE).sha
	cd \$(SVN_DIR) && svn status
	sleep 10
	cd \$(SVN_DIR) && svn ci -m \$(COMMIT_MSG_FILES)

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

\$(SVN_DIR):
	svn mkdir --parents \$(CANDIDATE_URL) -m \$(COMMIT_MSG_DIR)
	sleep 10
	svn co \$(CANDIDATE_URL) \$@

email: \$(EMAIL_FILE)
	cat \$(EMAIL_FILE)

\$(EMAIL_FILE): \$(EMAIL_TPL)
	sed -e "s|%version%|\$(VERSION)|g" \
	    -e "s|%candidate%|\$(CANDIDATE)|g"  \
	    -e "s|%candidate_url%|\$(CANDIDATE_URL)|g" \
	    -e "s|%package%|\$(PACKAGE)|g" > \
	    \$@ < \$<
EOF

log "Checking candidate into Subversion..."

make -f $build_file

log "Generating email template..."

make -f $build_file email

email_file=$tmp_dir/email.txt

echo "Email text written to:" $email_file

if test -n `which pbcopy`; then
    cat $email_file | pbcopy && copied=1
elif test -n `which xclip`; then
    cat $email_file | xclip -selection c && copied=1
elif test -n `which clip`; then
    cat $email_file | clip && copied=1
fi

if test -n "$copied"; then
    echo "Copied to your clipboard..."
fi

echo "Send the email to: dev@couchdb.apache.org"

echo "Files in $tmp_dir"
