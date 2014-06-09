#!/bin/bash

[ -z "$1" ] && echo user, please && exit -1
[ -z "$2" ] && echo outdir, please && exit -1
ljuser=$1
out="$2"

function filter {
    perl -pe '
    s,http://'$ljuser'.livejournal.com/(\d+).html,/p/$1/,g;
    s/([^:]\()\s+/$1/g;
    s/^\s+//;
    s/,^\s/, /g;
    s/&nbsp;\s+/&nbsp;/g;
    s/\s+&nbsp;/&nbsp;/g;
    s/&laquo;\s+/&laquo;/g;
    '
}

function do_file {
    f=$1
    echo $f
    tags=
    title='"'$(grep 'dt class="entry-title"' $f | sed -e 's/.*class="entry-title">\([^<]*\)<.*/\1/' -e 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g' | filter)'"'
    [ "$title" = '""' ] && title='"(empty subject)"'
    d=$(grep 'dd class="entry-date"' $f | sed -e 's/.*title="\([^"]*\)".*/\1/')
    p=$(grep 'div class="entry-content"' $f)
    text=$(echo "$p" | sed -e 's/<div class="entry-content">//' -e "s/<div class='ljtags'>Tags: .*//" -e 's/<div.*>//g' -e 's,</div>,,g')
    text=$(echo "$text" | filter | fold -s -w 150)

    if echo "$p" | grep "<div class='ljtags'>Tags:" >/dev/null; then
        tags=$(echo "$p" | sed -e 's/<div class="entry-content">//' -e "s/.*<div class='ljtags'>Tags: //")
        tags=$(echo "$tags" | sed -e "s/<a rel='tag'/\n<a rel='tag'/g" | sed -e "s/.*<a rel='tag' [^>]*>\([^<]*\)<.*/\1/g")
    fi
    tags="["$(echo "$tags" | grep -v '^$' | paste -sd,)"]"
iconv -c -t utf8 >$out/$(basename $f) << EOF
---
title: $title
created_at: $d
tags: $tags
original_url: http://$ljuser.livejournal.com/$(basename $f)
---
$text
EOF
}


mkdir $out
find -L $ljuser -type f -iname '*.html' | sort | while read f; do
    do_file $f &
    nwait.sh 20
done

wait

rm $out/index.html
