#/bin/bash 
which ff || exit 1
which npx && npm install wrangler
test -e .env && source .env
PARDIR=$(pwd)
test -e cache || mkdir cache 
test -e logs || mkdir logs
cd cache || exit 1
STARTDIR=$(pwd)

[[ -z "$GIST_TOKEN" ]] && echo NO GIST_TOKEN
[[ -z "$GIST_TOKEN" ]] && exit 1
[[ -z "$GIST_ID" ]] && echo NO GISTID
[[ -z "$GIST_ID" ]] && exit 1


echo "cloning "

test -e ${PARDIR}/logs && (
test -e ${PARDIR}/logs && ( cd ${PARDIR}/logs || ( rm -rf ${PARDIR}/logs;mkdir ${PARDIR}/logs) );
)


 
test -e ${PARDIR}/pages && (
test -e ${PARDIR}/pages && ( cd ${PARDIR}/logs || ( rm -rf ${PARDIR}/pages;mkdir ${PARDIR}/pages) );
)
test -e ${PARDIR}/pages || mkdir  ${PARDIR}/pages
test -e ${PARDIR}/logs  || mkdir  ${PARDIR}/logs
test -e ${PARDIR}/logs  && (   echo found log path )
test -e ${PARDIR}/pages && ( echo found pages path )
test -e ${PARDIR}/logs/fetch.log && (echo > ${PARDIR}/logs/fetch.log)
test -e ${PARDIR}/logs/main.log && (echo > ${PARDIR}/logs/main.log)
test -e ${PARDIR}/logs/curl.log && (echo > ${PARDIR}/logs/curl.log)
test -e ${PARDIR}/logs/pages.log && (echo > ${PARDIR}/logs/pages.log)
test -e ${PARDIR}/logs/files.log && (echo > ${PARDIR}/logs/files.log)
 #echo git clone https://gist.github.com/${GIST_ID}.git index;
 timeout 10 git clone https://gist.github.com/${GIST_ID}.git index &>/dev/null || git clone  https://$GIT_USER:$GIST_TOKEN@gist.github.com/${GIST_ID} index  2>&1 ;
 
 cd index || exit 1
 
 git remote -v 
 #echo "MOUNTING RW"
 git remote set-url origin https://$GIT_USER:$GIST_TOKEN@gist.github.com/${GIST_ID}".git"
 git status
year=$(date -u +%Y);
#test -e "$year"|| mkdir "$year";

urllist=$(curl -s https://incredinews.github.io/feed-sources/raw/lang/de.rss.json|grep "http"|cut -d'"' -f2;curl -s https://incredinews.github.io/feed-sources/raw/lang/en.rss.json|grep "http"|cut -d'"' -f2)
 
 echo > ${PARDIR}/logs/main.log
 echo > ${PARDIR}/logs/curl.log
 fullist=$(
 (
 echo "$urllist"
 test -e ADDON_FEEDS && cat ADDON_FEEDS |grep -v "^#"|grep -e ftp:// -e http:// -e https://
 [[ -z "$ADDON_FEEDS" ]] || echo "$ADDON_FEEDS" 
 )|sort -u
  ) 
  
  echo "LEN:"$(echo "$fullist"|wc -l )
  for url in $(echo "$fullist");do 
    basedurl=$(echo -n "$url"|base64 -w 0|sed 's/=/_/g');
    safeurl=$(echo -n "$url"|sed 's/=/_/g;s/=/"/g;s/=/~/g;s/\//_/g;s/:/_/g'|sed 's/https___//g'|sed 's/http___//g')

    id=""
    test -e "${STARTDIR}/index/${year}_${basedurl}" && { 
        (
        #echo found file for "$url" as $basedurl;
        id=$(cat "${year}_${basedurl}"|jq  -r .id)
        
        [[ "$id" = "null" ]] && {   echo "failed to find id ..deleting idx" ;grep -q "$GIT_USER" "${year}_${basedurl}" && echo "sems like authetication problems"; cat ${year}_${basedurl} ; rm "${year}_${basedurl}" ; } ;
        #[[ "$id" = "null" ]] || {   echo "found at "$id  ; } ;
        ) &>> ${PARDIR}/logs/main.log

        }
    test -e "${STARTDIR}/index/${year}_${basedurl}" || {
        (
        echo "missing SOURCE ${year}_${basedurl} .. creating store"
        curl -H "Authorization: Bearer ${GIST_TOKEN}" -X POST -o "${year}_${basedurl}" -d '{"public":"false","description":"json_feed:'"${basedurl}"'@'"$(date  -u +%s)"'","files":{"README.md":{"content":" feed_store for '"$url"'"}}}' https://api.github.com/gists 
        id=$(cat "${year}_${basedurl}"|jq  -r .id)
        [[ "$id" = "null" ]] && {   echo "failed to find id ..deleting idx" ; } ;
        [[ "$id" = "null" ]] || {   echo "created at "$id  ; } ;
        ) 2>&1 |sed 's~^~'"$safe"' : ~ g' >> ${PARDIR}/main.log & 
        sleep 2
    echo -n ; } ;
done
  
wait
  
  
 
 ( cd ${STARTDIR}/index/ && (
    git config  user.name "User.Name"
    git config  user.email "gist@github.com" 

 
    git status --porcelain|wc -l |grep -q 0 || {
    echo "SAVING INDEX"
    git remote set-url origin https://$GIT_USER:$GIST_TOKEN@gist.github.com/${GIST_ID}".git"
    git status
                 ( git add -A 2>&1 ;git commit -m "updates $(date -u)" 2>&1 ;git push 2>&1 ) |sed 's/^/PUSH_MAIN:/g' 

        echo -n ; } ; )
   ) &>> ${PARDIR}/logs/main.log

echo 1 >/tmp/counter
  for url in $(echo "$fullist");do 
 
  echo 
  echo -n "...#"$(cat /tmp/counter)"|"
  echo $(($(cat /tmp/counter)+1)) > /tmp/counter
  


 
    cd ${STARTDIR}/index/
    basedurl=$(echo -n "$url"|base64 -w 0|sed 's/=/_/g');
    safeurl=$(echo -n "$url"|sed 's/=/_/g;s/=/"/g;s/=/~/g;s/\//_/g;s/:/_/g'|sed 's/https___//g'|sed 's/http___//g')

    echo ;
   
    year=$(date -u +%Y);
         
        test -e "${year}_${basedurl}" || { echo ":NO target dir:" ; } ;
        test -e "${year}_${basedurl}" && { 
           #verify a readable json
           id=$(cat "${year}_${basedurl}"|jq  -r .id)
           [[ "$id" = "null" ]] && { echo ":ID NOT READABLE:" ; } ;
           [[ "$id" = "null" ]] || { 
            test -e "${STARTDIR}/store_$id" && echo    "|FILES#:"$(find ${STARTDIR}/store_$id/ -type f|grep -v "\.git" |wc -l )"|"

            (
#            echo
            echo -n "LOAD:"$( cut -d" " -f1-3 /proc/loadavg)"|"
            echo -n PROCESSING "$url" as $basedurl;
             test -e "${STARTDIR}/store_$id" && echo "|FILES COUNT:"$(find ${STARTDIR}/store_$id/ -type f|grep -v "\.git" |wc -l )"|"



            test -e "${STARTDIR}/store_$id"  || (            echo "loading $id"  ;
                timeout 15 git clone https://gist.github.com/${id}.git "${STARTDIR}/store_$id"  &>/dev/null || git clone  https://$GIT_USER:$GIST_TOKEN@gist.github.com/${id}".git"  "${STARTDIR}/store_$id" 2>&1|sed 's/^/CLONE_'"${id}"':/g' ) 

            test -e "${STARTDIR}/store_$id" && {  

              cd  "${STARTDIR}/store_$id"
              #pwd
              update=yes
              test -e fetch.status && gettime=$(date -d  $(cat fetch.status |cut -d'"' -f2) +%s);
              now=$(date +%s) ; 
              [[ $(($now-$gettime)) -le 1234 ]] && update=no
              test -e fetch.status || update=yes
              ## debounce above around 20 min, fetch always if no status
              [[ "$update" = "yes" ]] && test -e "${STARTDIR}/store_$id"  && (
              (  echo "pulling $id";cd  "${STARTDIR}/store_$id" ; git remote set-url origin https://$GIT_USER:$GIST_TOKEN@gist.github.com/${id}".git" ;git pull |sed 's/^/PULL_'"${id}"':/g' )
              )
              test -e "${STARTDIR}/store_$id" && test -e "${STARTDIR}/store_$id/fetch.status" && cat  "${STARTDIR}/store_$id/fetch.status"  |sed 's/http.\+//g' |sed 's/^/BFORE:/g'
              test -e README.md && mv README.md 0_README.md
              echo -n "LOAD:"$( cut -d" " -f1-3 /proc/loadavg)"|update=$update |"

              [[ "$update" = "yes" ]] && {
				   cd  "${STARTDIR}/store_$id"
                  #echo -n "LOAD (w "$(pwd;echo "@" ;which ff)"):"
                  echo -n "LOAD (w "$(which ff)"):"
                  echo $( test -e fetch.status && echo "("$(($now-$gettime))"s ago )" ; )" "
                    test -e last.fetch && rm last.fetch
                    test -e last.json  && rm last.json
                    test -e current.json &&  ( mv current.json last.json  &>>${PARDIR}/logs/files.log )
                    test -e fetch.status &&  ( mv fetch.status last.fetch &>>${PARDIR}/logs/files.log )
                    ##get a json array
                    (echo -n "[";ff  "$url" 2>fetch.status |sed "s/$/,/g")|tr -d '\n'|sed 's/,$/]/g' > current.json 
                    validjson=no
                    (cat current.json |jq .>/dev/null) && validjson=yes
                    test -e fetch.status && echo "RES:"$(cat fetch.status)" JSON_OK:"$validjson
                    #grep -q 'msg="fetched ' fetch.status && curl -kLv "$url" -o current.xml 2>> ${PARDIR}/logs/curl.log
                    curl -kLv "$url" -o current.xml 2>> ${PARDIR}/logs/curl.log



                    #test -e fetch.status && cat fetch.status
                    test -e last.json && rm last.json
                    test -e last.fetch && rm last.fetch
                    test -e "${STARTDIR}/store_$id"  &&  test -e    "${STARTDIR}/store_$id/fetch.status" && cat  "${STARTDIR}/store_$id/fetch.status"  |sed 's/http.\+//g' |sed 's/^/AFTER:/g'

                    (cat current.json |jq .>/dev/null) && python3 ${PARDIR}/process-ff-item.py 2>&1 
                    ## restore on failure
                    #grep -q 'fetched http' fetch.status || ( echo using backup;test -e last.json && (cp last.fetch fetch.status; cp last.json current.json)   )

                    [[ "$validjson" = "yes" ]] ||  ( echo using backup;test -e last.json && (cp last.fetch fetch.status; cp last.json current.json)   )
                    
                    test -e ${PARDIR}/logs/curl.log && rm ${PARDIR}/logs/curl.log
                   
                echo -n ; } ;

              [[ "$update" = "no" ]] && {    
                    echo -n "WAIT:"
                    echo $( test -e fetch.status && echo "("$(($now-$gettime))"s ago )" ; )" "
                echo -n ; } ; 
              
            echo -n ; } ;
              branchname=$(echo "$basedurl"|sed 's/_/=/g'|base64 -d|cut -d"/" -f3|sed 's/\./-/g')
              test -e ${PARDIR}/pages/${branchname} || mkdir ${PARDIR}/pages/${branchname}
              
              test -e "${STARTDIR}/store_$id"  && (cd "${STARTDIR}/store_$id" && ( cd "${STARTDIR}/store_$id";find -type f -name "*.json"; find -type f -name "*.xml" )) | while read outfile;do
                 
                 outname=$(echo "${outfile}" |sed 's/^/'${basedurl}'/g'|sed 's~\./~/~g'|sed 's~/\+~/~g'|sed 's~/~.~g')
                 [[ "$DEBUGME" = "true" ]] && echo "copy $outfile | AS |$outname| to | ${PARDIR}/pages/${branchname}/ " &>>${PARDIR}/logs/files.log 
                 
                 cp "${STARTDIR}/store_$id/$outfile" "${PARDIR}/pages/${branchname}/${outname}"      &>>${PARDIR}/logs/files.log 
                 
              done
              grep -q -e "http error: 404 Not Found" fetch.status || (git status --porcelain|wc -l |grep -q 0 || {
                  echo -n "pushing "$(git remote -v |cut -d @ -f2- |head -n 1)"|$(test -e fetch.status && cat fetch.status)"
                  #test -e fetch.status && cat fetch.status
                  
                  git status 2>&1|grep -e modified -e ndert -e json
                  git config  user.name "User.Name"
                  git config  user.email "gist@github.com" 
 
                  git remote set-url origin https://$GIT_USER:$GIST_TOKEN@gist.github.com/${id}.git
                  ( git remote -v 2>&1 |cut -d @ -f2- |head -n1 ;git add -A 2>&1 |sed 's/\t/ /g' |tr -d '\n';git commit -m "updates $(date -u)" 2>&1|sed 's/\t/ /g' |tr -d '\n'|sed 's/modified/µ/g' ;git push 2>&1|grep -v origin |sed 's/\t/ /g' |tr -d '\n') |sed 's/^/PUSH_'"${id}"':/g' &
                  echo -n ; } ;
              )
               ) 2>&1 |sed 's~^~'"$safeurl"' : ~g'  >> ${PARDIR}/logs/fetch.log & 

              echo -n ; } ;
              
        } & 
        sleep 2
#grep msg=  ${PARDIR}/logs/*.log |sed 's/http.\+//g' |sort -u

done
sleep 10;
wait 

test -e ${PARDIR}/logs/pages.log && (echo >${PARDIR}/logs/pages.log )
cansend=yes
[[ -z "$CLOUDFLARE_API_TOKEN" ]] && cansend=no
[[ -z "$CF_PAGESPROJECT" ]] && cansend=no
(
cd ${PARDIR}/pages/
echo 1 >/tmp/counter
[[ "$cansend" = "yes" ]] && test -e ${PARDIR}/pages/ &&  for sendbranch in $(cd ${PARDIR}/pages/;ls -d1 *);do


 
  echo 
  echo "PAGE...#"$(cat /tmp/counter)
  echo $(($(cat /tmp/counter)+1)) > /tmp/counter
  
(
(cd "$sendbranch" && ( find -type f > index.txt ))
find "${PARDIR}/pages/$sendbranch" -type f|wc -l |grep -q ^1$ || ( which npx &>/dev/null  &&  (npx wrangler pages deploy --project-name "$CF_PAGESPROJECT" --commit-dirty=true --branch "$sendbranch" "$sendbranch" 2>&1 |sed 's/\r/\n/g' |grep -v -e "Deploying\.\." -e "Uploading\.\."|tr -d '\n')) & sleep 10
) &>>${PARDIR}/logs/pages.log &
sleep 3

sleep $(($(($(cat /tmp/counter)+1))%42))
done
wait
)

(
cd ${PARDIR}/pages/
[[ "$cansend" = "yes" ]] && test -e ${PARDIR}/pages/ &&  (
mkdir main
( find -type f -name "*.json" ;find -type f -name "*.xml" ) > main/index.txt
cat main/index.txt | jq -Rn '{date: "'$(date -u +%s)'", lines: [inputs]}' > main/index.json

which npx &>/dev/null  &&  ( npx wrangler pages deploy --project-name "$CF_PAGESPROJECT" main 2>&1 |sed 's/\r/\n/g' |grep -v -e "Deploying\.\." -e "Uploading\.\."|tr -d '\n' )
) &>>${PARDIR}/logs/pages.log 
)
ls -1
cd ${PARDIR}
pwd
grep msg= logs/main.log logs/.log |sort -u
test -e logs && (echo logs there;du -m -s logs)
test -e pages && (echo logs here)
