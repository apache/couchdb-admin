#!/bin/sh -e

basename=`basename $0`

ssh people.apache.org "sh -e" <<EOF

tmp_dir=\`mktemp -d /tmp/$basename.XXXXXX\` || exit 1

mbox_export_file=\$tmp_dir/mbox

cve_list_file=\$tmp_dir/cve_list.txt

log () {
    printf "\033[1;31m\$1\033[0m\n"
}

log "Adding mails to export..."

find /home/apmail/private-arch/security -type f | while read mbox_file; do
    compressed=\`echo \$mbox_file | grep -E "\.gz" || true\`
    if test -n "\$compressed"; then
        echo "Adding" \$mbox_file "(compressed)"
        cat \$mbox_file >> \$mbox_export_file
     else
        echo "Adding" \$mbox_file
        cat \$mbox_file | gzip >> \$mbox_export_file
    fi
done

log "Finding CVE numbers..."

zgrep "CVE" \$mbox_export_file | \
    grep "Apache CouchDB" | \
    sed "s,.*CVE,CVE," | \
    cut -c1-13 | \
    grep -E "CVE-[0-9]{4}-[0-9]{4}" | \
    grep -v "CVE-2008-2370" | \
    sort | \
    uniq | \
    tee \$cve_list_file

rm \$mbox_export_file

log "Writing CVE numbers..."

echo \$cve_list_file
EOF
