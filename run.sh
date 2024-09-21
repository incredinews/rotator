#/bin/bash 
which ff || exit 1

git config --global user.name "User.Name"
git config --global user.email "gist@github.com" 

 
 STARTDIR=$(pwd)
 echo "cloning "
 
 echo git clone https://gist.github.com/${GIST_ID}.git index;
 timeout 10 git clone https://gist.github.com/${GIST_ID}.git index || git clone  https://$GIT_USER:$GIST_TOKEN@gist.github.com/$GIST_ID index ;
 
 cd index || exit 1
 
 git remote -v 
 #echo "MOUNTING RW"
 #git remote set-url origin https://$GIT_USER:$GIST_TOKEN@gist.github.com/$GIST_ID
 git status
year=$(date -u +%Y);
#test -e "$year"|| mkdir "$year";

urllist=$(curl -s https://incredinews.github.io/feed-sources/raw/lang/de.rss.json|grep "http"|cut -d'"' -f2)
 echo "$urllist"|while read url;do 
    basedurl=$(echo -n "$url"|base64 -w 0|sed 's/=/_/g');
    id=""
    test -e "${year}_${basedurl}" && { 
        echo found file for "$url" as $basedurl;
        id=$(cat "${year}_${basedurl}"|jq  -r .id)
        [[ "$id" = "null" ]] && {   echo "failed to find id ..deleting idx" ; rm "${year}_${basedurl}" ; } ;
        [[ "$id" = "null" ]] || {   echo "found at "$id  ; } ;
        }
    test -e "${year}_${basedurl}" || {
        echo "missing SOURCE ${year}_${basedurl} .. creating store"
        curl -H "Authorization: Bearer ${GIST_TOKEN}" -X POST -o "${year}_${basedurl}" -d '{"public":"false","description":"json_feed:'"${basedurl}"'@'"$(date  -u +%s)"'","files":{"README.md":{"content":" feed_store for '"$url"'"}}}' https://api.github.com/gists 
        id=$(cat "${year}_${basedurl}"|jq  -r .id)
        [[ "$id" = "null" ]] && {   echo "failed to find id ..deleting idx" ; } ;
        [[ "$id" = "null" ]] || {   echo "created at "$id  ; } ;
    echo -n ; } ;
done
 
 ( cd ${STARTDIR}/index/ && (
    git status --porcelain|wc -l |grep -q 0 || {
    echo "SAVING INDEX"
    git remote set-url origin https://$GIT_USER:$GIST_TOKEN@gist.github.com/$GIST_ID
    git status
                git add -A ;git commit -m "updates $(date -u)";git push 
        echo -n ; } ; )
 )
 echo "$urllist"|while read url;do 
    cd ${STARTDIR}/index/
    basedurl=$(echo -n "$url"|base64 -w 0|sed 's/=/_/g');echo PROCESSING "$url" as $basedurl;year=$(date -u +%Y);
        test -e "${year}_${basedurl}" && { 
        id=$(cat "${year}_${basedurl}"|jq  -r .id)
        [[ "$id" = "null" ]] || {   
            test -e "${STARTDIR}/store_$id"  && (echo "pulling $id";cd  "${STARTDIR}/store_$id" ;git pull )

            test -e "${STARTDIR}/store_$id"  || (            echo "loading $id"  ;
                timeout 15 git clone https://gist.github.com/${id}.git "${STARTDIR}/store_$id" || git clone   https://$GIT_USER:$GIST_TOKEN@gist.github.com/$id  "${STARTDIR}/store_$id" )
            
            test -e "${STARTDIR}/store_$id" && {  cd  "${STARTDIR}/store_$id"
            pwd
            test -e README.md && mv README.md 0_README.md
            (echo -n "[";ff  "$url" 2>fetch.status |sed "s/$/,/g")|tr -d '\n'|sed 's/,$/]/g' > current.json 
            cat fetch.status
            python3 ${STARTDIR}/process-ff-item.py 2>&1 
                  echo -n ;} ;
                  
            git status --porcelain|wc -l |grep -q 0 || {
                echo "pushing "$(git remote -v |head -n 1)
                git status
                git remote set-url origin https://$GIT_USER:$GIST_TOKEN@gist.github.com/$id
                git add -A ;git commit -m "updates $(date -u)";git push 
                echo -n ; } ;
            echo -n ; } ;
        }
    
done
