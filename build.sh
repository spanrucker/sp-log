#!/bin/bash

# site config

site_name="simon's log"
site_url="https://spanrucker.github.io/sp-log"
site_description="simon panrucker's creative log"
site_footer="simon@simonpanrucker.com"
posts_per_page=10


# set up variables

list=$(ls -r ./post/* | grep -E -i '\.md$|\.mp3$|\.jpg$')
postnum=0
posts=( $list )
target=index
pagemax=$posts_per_page



sed -e "s|{{SITE_NAME}}|$site_name|
    s|{{SITE_URL}}|$site_url|
    s|{{SITE_DESCRIPTION}}|$site_description|" rss_start.xml_ > rss.xml

for file in $list 
do
    # set up variables
    pagenum=$((postnum/pagemax))
    remainder=$((postnum%pagemax))
    fileandext="${file##*/}"
    extension="${fileandext##*.}"
    filename="${fileandext%.*}"
    caption="./post/${filename}.txt"
    postnum=$((postnum+1))

    # page construction
    if [[ $pagenum = 0 ]]; then
        target="index"
    else
        target=$pagenum
    fi

    if [[ $remainder = 0 ]]; then
        sed -e "s|{{SITE_NAME}}|$site_name|
        s|{{SITE_DESCRIPTION}}|$site_description|" start.htm_ > $target.html
                if [[ $pagenum -eq 1 ]]; then
            echo "<p><a href=\"/\">after &uarr;</a></p>" >> $target.html
        elif [[ ! $pagenum -eq 0 ]]; then
            echo "<p><a href=\"$((pagenum - 1)).html\">&uarr; after</a></p>" >> $target.html
        fi
    fi
    
    sed -e "s|{{SITE_URL}}|$site_name|
        s|{{SITE_NAME}}|$site_name|
        s|{{SITE_DESCRIPTION}}|$site_description|" start.htm_ > $filename.html

    # entry construction

    echo "<article>" | tee -a $target.html >>$filename.html

    # entry link / title
    echo "<p><a href="$filename.html">$filename</a></p>" >> $target.html
    echo "<p><strong>$filename</strong></p>" >> $filename.html

    # rss
    if [[ $postnum -lt 10 ]]; then
        echo "<item>" >> rss.xml
        echo "<title>$filename</title>" >> rss.xml
        echo "<link>$site_url/$filename.html</link>" >> rss.xml
        echo "<guid>$site_url/$filename.html</guid>" >> rss.xml
        echo "<description>New post on $site_name</description>" >> rss.xml
        date=$(date -Rd "${filename:0:10}")
        echo "<pubDate>$date</pubDate>" >> rss.xml 
        echo "</item>" >> rss.xml
    fi

    # output html for each filetype

    if [[ "$extension" == "mp3" ]]; then
        echo "<p><audio src=\"$file\" controls>$file</audio></p>" | tee -a $target.html >>$filename.html
    elif [[ "$extension" == "md" ]]; then
        cmark --unsafe ${file} | tee -a $target.html >>$filename.html 

    elif [[ "$extension" == "jpg" ]] || [[ "$extension" == "JPG" ]]; then
        if [ ! -d "./image/big" ]; then
        mkdir -p ./image/big
        fi
        if [ ! -f ./image/$filename.jpg ]; then
        convert $file -resize "800>" ./image/$filename.jpg
        convert $file -resize "2400>" ./image/big/$filename.jpg
        fi
        echo "<p><a href=\"./image/big/$filename.jpg\"><img alt="$filename" src=\"./image/$filename.jpg\"></a>" | tee -a $target.html >>$filename.html 
    fi

    # add caption if .txt file found

    if [ -f $caption ]; then
        cmark $caption | tee -a $target.html >>$filename.html
    fi

    # page construction end

    echo "</article>" | tee -a $target.html >>$filename.html

    if [ $remainder = $(($pagemax - 1)) ] || [ $postnum = ${#posts[@]} ]; then
        echo "<p>" >> $target.html

        if [ ! $postnum = ${#posts[@]} ]; then
            echo "<a href=\"$(($pagenum + 1)).html\">before &darr;</a>" >> $target.html
        fi
        echo "</p>" >> $target.html
        sed -e "s|{{SITE_FOOTER}}|$site_footer|" end.htm_ >> $target.html

    fi


    sed -e "s|{{SITE_FOOTER}}|$site_footer|" end.htm_ >> $filename.html


done

cat rss_end.xml_ >> rss.xml

