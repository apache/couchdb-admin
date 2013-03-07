#!/bin/sh -e

GIT_URL=https://git-wip-us.apache.org/repos/asf?p=couchdb.git;a=blob_plain;

EMAIL_TPL=email/discuss_release.txt

if test -n "$1"; then
    cache_dir=$1
else
	echo "error: no cache directory"
    exit 1
fi

if test -n "$2"; then
    branch=$2
else
	echo "error: no branch"
    exit 1
fi

if test -n "$3"; then
    version=$3
else
	echo "error: no version"
    exit 1
fi

log () {
    printf "\033[1;31m$1\033[0m\n"
}

basename=`basename $0`

tmp_dir=`mktemp -d /tmp/$basename.XXXXXX` || exit 1

log "Parsing documentation..."

email_in_file=$tmp_dir/email.txt.in

cat $EMAIL_TPL > $email_in_file

python <<EOF
def get_section(doc_path, version):
    doc_file = open(doc_path)
    copy = False
    section = ""
    for line in doc_file.readlines():
        if line.startswith("Version"):
            if line == "Version $version\n":
                copy = True
                continue
            else:
                if copy:
                    break
        if line.startswith("-"):
            continue
        if copy:
            if line.strip():
                section += line
    return section.rstrip()

news = get_section("$cache_dir/branch/$branch/NEWS", "$version")

email_in_file = open("$email_in_file")

email_in_file_content = email_in_file.read()

email_in_file_content = email_in_file_content.replace("%news%", news)

email_in_file = open("$email_in_file", "w")

email_in_file.write(email_in_file_content)
EOF

email_file=$tmp_dir/email.txt

changes=$GIT_URL"f=CHANGES;hb=$branch"

sed -e "s|%version%|$version|g" \
    -e "s|%changes%|$changes|g" \
    < $email_in_file > $email_file

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
