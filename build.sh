#!/bin/bash

list=$(ls -r ./post/* | grep -E -i '\.md$|\.mp3$|\.jpg$')
postnum=0
pagemax=10
posts=( $list )
target=index
sitename="s.panrucker"
siteurl="https://s.panrucker.co"


cat rss_start.xml_ > rss.xml

for file in $list 
do
    # set up variables
    pagenum=$((postnum/pagemax))
    remainder=$((postnum%5))
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
        cat start.htm_ > $target.html
                if [[ $pagenum -eq 1 ]]; then
            echo "<p><a href=\"index.html\">after &uarr;</a></p>" >> $target.html
        elif [[ ! $pagenum -eq 0 ]]; then
            echo "<p><a href=\"$((pagenum - 1)).html\">&uarr; after</a></p>" >> $target.html
        fi
    fi
    
    cat start.htm_ > $filename.html

    # entry construction

    echo "<article>" | tee -a $target.html >>$filename.html

    # entry link / title
    echo "<p><a href="$filename.html">$filename</a></p>" >> $target.html
    echo "<p><strong>$filename</strong></p>" >> $filename.html

    # rss construction

    echo "<item>" >> rss.xml
    echo "<title>s.panrucker</title>" >> rss.xml
    echo "<link>https://s.panrucker.co</link>" >> rss.xml
    echo "<guid>https://s.panrucker.co/$filename.html</guid>" >> rss.xml
    echo "<description><![CDATA[" >> rss.xml
   

    # output html for each filetype

    if [[ "$extension" == "mp3" ]]; then
        echo "<p><audio src=\"$file\" controls>$file</audio></p>" | tee -a $target.html >>$filename.html
        echo "New audio post on s.panrucker" >>rss.xml
    elif [[ "$extension" == "md" ]]; then
        cmark --unsafe ${file} | tee -a $target.html >>$filename.html 
        echo "New text post on s.panrucker" >>rss.xml

    elif [[ "$extension" == "jpg" ]] || [[ "$extension" == "JPG" ]]; then
        if [ ! -d "./image/big" ]; then
        mkdir -p ./image/big
        fi
        if [ ! -f ./image/$filename.jpg ]; then
        convert $file -resize "800>" ./image/$filename.jpg
        convert $file -resize "2400>" ./image/big/$filename.jpg
        fi
        echo "<p><a href=\"./image/big/$filename.jpg\"><img alt="$filename" src=\"./image/$filename.jpg\"></a>" | tee -a $target.html >>$filename.html 
        echo "New image post on s.panrucker" >>rss.xml
    fi

    # add caption if .txt file found

    if [ -f $caption ]; then
        cmark $caption | tee -a $target.html >>$filename.html >>rss.xml
    fi

    # page construction end

    echo "</article>" | tee -a $target.html >>$filename.html

    if [ $remainder = $(($pagemax - 1)) ] || [ $postnum = ${#posts[@]} ]; then
        echo "<p>" >> $target.html

        if [ ! $postnum = ${#posts[@]} ]; then
            echo "<a href=\"$(($pagenum + 1)).html\">before &darr;</a>" >> $target.html
        fi
        echo "</p>" >> $target.html
        cat end.htm_ >> $target.html

    fi


    cat end.htm_ >> $filename.html

    # close rss
    echo "]]></description>" >> rss.xml
    date=$(date -Rd "${filename:0:10}")
    echo "<pubDate>$date</pubDate>" >> rss.xml 
    echo "</item>" >> rss.xml
done

cat rss_end.xml_ >> rss.xml

