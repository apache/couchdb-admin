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

GIT_URL="https://git-wip-us.apache.org/repos/asf?p=couchdb.git;a=blob_plain;"

EMAIL_TPL=discuss_release.txt

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

cd `dirname $0`

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

email_in_file_content = email_in_file_content.replace("%NEWS%", news)

email_in_file = open("$email_in_file", "w")

email_in_file.write(email_in_file_content)
EOF

email_file=$tmp_dir/email.txt

changes=$GIT_URL"\&f=CHANGES;hb=$branch"

sed -e "s|%VERSION%|$version|g" \
    -e "s|%CHANGES%|$changes|g" \
    < $email_in_file > $email_file

echo "Email text written to:" $email_file

echo "Send the email to: dev@couchdb.apache.org"

echo "Files in: $tmp_dir"
