#!/bin/bash 
[[ -z "$RESTURL"  ]] && exit 1
[[ -z "$RESTPASS" ]] && exit 1
[[ -z "$DAVURL"   ]] && exit 1
[[ -z "$TSTOKEN"  ]] && exit 1
[[ -z "$TSURL"    ]] && exit 1
[[ -z "$RESTACK"  ]] && exit 1
[[ -z "$RESTSKY"  ]] && exit 1
export RESTIC_PASSWORD="$RESTPASS"
export RESTIC_FROM_PASSWORD="$RESTPASS"
export RESTIC_REPOSITORY="$RESTURL";export AWS_SECRET_ACCESS_KEY="$RESTSKY";export AWS_ACCESS_KEY_ID="$RESTACK"
export SECREADY=true
[[ -z $SECRESTACK       ]] && export SECREADY=false
[[ -z $SECRESTSKY       ]] && export SECREADY=false
[[ -z $SECRESTURL ]] && export SECREADY=false

#[[ -z "$RESTSEC"  ]] && exit 1
  

cd /tmp/
test -e /tmp/feedarch||mkdir /tmp/feedarch
cd /tmp/feedarch
test -e /tmp/restic || mkdir /tmp/restic
restic -r /tmp/restic init|| true
export RESTIC_REPOSITORY="$RESTURL";export AWS_SECRET_ACCESS_KEY="$RESTSKY";export AWS_ACCESS_KEY_ID="$RESTACK"
restic init || true
[[ "$SECREADY" == "true" ]] && {  export RESTIC_REPOSITORY="$SECRESTURL";export AWS_SECRET_ACCESS_KEY="$SECRESTSKY";export AWS_ACCESS_KEY_ID="$SECRESTACK" ; restic init || true  ; } ; 
export RESTIC_REPOSITORY="$RESTURL";export AWS_SECRET_ACCESS_KEY="$RESTSKY";export AWS_ACCESS_KEY_ID="$RESTACK"

export RESTIC_REPOSITORY=/tmp/restic
deletelist=""

hourslist=$(lftp -e "open ""$DAVURL""feedarchive/;ls ;quit"|sed 's/.\+ --  //g'|grep _|grep "^[0-9]"|sort -u|grep -v $(date +%Y-%m-%d))
echo "found "$(echo "$hourslist"|wc -l)" hours"

for myhour in $hourslist;do

echo $(date )" : Load $myhour"
time lftp -e "open ""$DAVURL""feedarchive/;mirror -c --parallel=3 $myhour ;quit"
##links 
export SENT_SOMETHING=false
export RESTIC_REPOSITORY=/tmp/restic
for feed in $(ls "$myhour" -1|cut -d_ -f1|sort -u );do  
lastsum=""
lastcontentsum=""
test -e "/tmp/seen.$feed" && rm -rf "/tmp/seen.$feed"
test -e "/tmp/urls.$feed" && rm -rf "/tmp/urls.$feed"
test -e "/tmp/seen.$feed"  || mkdir -p "/tmp/seen.$feed" 
test -e "/tmp/urls.$feed"  || mkdir -p "/tmp/urls.$feed" 
  test -e /tmp/.del_$myhour || touch "/tmp/.del_$myhour"
  for arch in $(ls "$myhour" -1|grep $feed|sort -n|grep gz);do
      hostname=$(echo "$arch"|cut -d"_" -f1);
      timestamp=$(echo "$arch"|cut -d_ -f2-|cut -d"." -f1,2 |sed 's/_/ /g;s/\./:/g;s/$/:00/g');
      export RESTIC_HOST=$hostname
      links=$( cat "$myhour/$arch"|gunzip | tee "$myhour/"${arch/\.gz/} |jq .content|sed 's/\\n/\n/g'|sed 's/<link><!\[CDATA\[/<link>/g'|sed 's/\]\]><\/link>/<\/link>/g'|grep "<link"|sed 's/\\"//g'|sed 's/link href=/link>/g'|sed 's/<link/\n<link/g'|grep link |cut -d">" -f2|cut -d"<" -f1 |sed 's/?ref=rss\///g'|sed 's/\.html rel=/.html\nrel=/g'|sed 's/#ftag=[A-Za-z0-9]\+$//g' |grep -v ^$|grep -e ^ftp:// -e ^https:// -e ^http:// )
      filesum=$( md5sum "$myhour/"${arch/\.gz/} |  cut -d" " -f1                    )
      linksum=$(   echo "$links" |sort -n |md5sum|cut -d" " -f1 )
      echo  "  ==>>>    "$(du -k "$myhour/$arch"|cut -d" " -f1)
      echo  " Fs $filesum Ls $lastsum | Lns $linksum LnksBef $lastcontentsum "
      [[ "$filesum" == "$lastsum" ]]          && echo "DUPe"
      [[ "$linksum" == "$lastcontentsum" ]]   && echo "DUPeL"
      if [ $(echo "$links"|grep "://"|wc -l ) -ge 5 ]; then
         [[ "$linksum" == "$lastcontentsum" ]]  && ( echo "$myhour/$arch" >> "/tmp/.del_$myhour") 
         [[ "$filesum" == "$lastsum" ]]         && ( echo "$myhour/$arch" >> "/tmp/.del_$myhour")  
      fi
  datestamp=$(date +%s -u -d "$timestamp")
  echo $timestamp " links: "$(echo "$links"|wc -l)
  echo "$links" |while read link;do 
   curlinksum=$(echo "$link"|sha256sum|cut -d" " -f1)
   test -e "/tmp/urls.$feed"  || mkdir -p "/tmp/urls.$feed" 
   test -e "/tmp/seen.$feed"  || mkdir -p "/tmp/seen.$feed" 
    echo "$datestamp"                     >> "/tmp/seen.$feed/$curlinksum"
    test -e "/tmp/urls.$feed/$curlinksum" ||  echo "$link" > "/tmp/urls.$feed/$curlinksum"
    echo -n "+"
  done
  echo  

DO_ACTION=true
grep -q "window._cf_chl_opt.cOgUHash" "$myhour/"${arch/\.gz/}  && DO_ACTION=false
grep -q "Please enable JS and disable any ad blocker" "$myhour/"${arch/\.gz/}  && DO_ACTION=false

(echo "$links"|wc -l |grep -q -e ^0$ -e ^1$) && DO_ACTION=false
 echo will run: "$DO_ACTION"
 [[ "$DO_ACTION" == "true" ]] && { 
 echo "+--+"
  grep 'content' "$myhour/"${arch/\.gz/} -q && (echo "$myhour/$arch" >> "/tmp/.del_$myhour")
  grep 'content' "$myhour/"${arch/\.gz/} -q &&  export SENT_SOMETHING=true
  #mkfifo /tmp/rst.io &>/dev/null|| true 
  #cat /tmp/rst.io |sed 's/^/'"$myhour"'| ADD:/g' &
  ##echo restic backup --time "$timestamp" --host "$hostname" "$myhour/"${arch/\.gz/} 
  #     restic backup --time "$timestamp" --host "$hostname" "$myhour/"${arch/\.gz/} &> /tmp/rst.io  && ( echo "$myhour/$arch" >> "/tmp/.del_$myhour" )
echo -n ; } ;
  # end action 
  #test -e "$myhour/"${arch/\.gz/} && rm "$myhour/"${arch/\.gz/}  
lastsum="$filesum"
lastcontentsum="$linksum"
done; ## archive level


done ## feed level


##                      batch n items for timestamp
BATCHSIZE=44
echo "$TSURL"|grep -e "^//::1" -e "//127\.0\.0\.1" && export BATCHSIZE=99
#(echo "$arch" |grep -q ^5d25e83ff3270d5c3bb1d8603fde89f777fb) || ( echo "$links"| xargs -P 1 -n 44|while read list;do 
( for feed in $(ls "$myhour" -1|cut -d_ -f1|sort -u );do  ls -1 "/tmp/urls.$feed/" |while read n;do test -e /tmp/seen.$feed/$n && echo $feed/$n;done;done| xargs -P 1 -n $BATCHSIZE |while read sumlist;do 
  lotsout='"ts": {';loout='{"urls": [';
  hitsout='"ts": {';hiout='{"urls": [';
  hictr=0
  #echo $sumlist
  for elem in $sumlist;do 
  m=$(echo "$elem"|cut -d"/" -f2)
  feed=$(echo "$elem"|cut -d"/" -f1)
   #cat /tmp/urls.$feed/$m
  #( cat /tmp/urls.$feed/$m|grep -q -e ^http:// -e ^ftp:// -e ^redis:// -e ^rediss:// -e ^https:// -e ^dav:// -e ^davs:// -e ^smb:// -e ^s3:// ) || cat /tmp/urls.$feed/$m
   
   FEEDOK=true
   cat /tmp/urls.$feed/$m|grep "and a sneak peek of Jetpa" && FEEDOK=false

  [[ "$FEEDOK" == "true" ]] && (cat /tmp/urls.$feed/$m |grep  -q -e "^http://" -e "^ftp://" -e "^redis://" -e "^rediss://" -e "^https://" -e "^dav://" -e "^davs://" -e "^smb://" -e "^s3://") && {
  #echo found $m
    loval=$(cat /tmp/seen.$feed/$m|sort -n |head -n1)
    hival=$(cat /tmp/seen.$feed/$m|sort -n |tail -n1)
  #echo $loval $hival
     loout="$loout"'"'"$(cat /tmp/urls.$feed/$m)"'",';lotsout="$lotsout"'"'"$(cat /tmp/urls.$feed/$m)"'": '"$loval"',' ;
    [[ "$loval" == "$hival" ]] || {
     hiout="$hiout"'"'"$(cat /tmp/urls.$feed/$m)"'",';hitsout="$hitsout"'"'"$(cat /tmp/urls.$feed/$m)"'": '"$hival"',' ;
     hictr=$(( $hictr + 1 ))
    }
  echo -n ; } ; 
  done  

  lojsonout=$(echo "$loout"|sed 's/,$/],/g')$(echo "$lotsout"|sed 's/,$/}/g')"}"  ;
  hijsonout=$(echo "$hiout"|sed 's/,$/],/g')$(echo "$hitsout"|sed 's/,$/}/g')"}"  ;
  loctr=$(echo "$lojsonout"|jq -c .urls[] 2>/dev/null|wc -l  )
  echo "GOT LIST of":$(echo "$sumlist"|wc -w)" ↓ "$loctr" ↓ | ↑ "$hictr" ↑"
  #echo "$jsonout"|jq . -c ;#echo "$jsonout"
  #echo "JSON: $hijsonout"
  #echo "$loctr"| grep -q ^0$ || ( curlres=$(curl -s -H "API-KEY: $TSTOKEN" "${TSURL}" -H "Content-Type: application/json" -X POST  --data "${lojsonout}" );echo "$curlres"|jq . &>/dev/null || echo "$curlres";echo "$curlres"|jq .|grep -q "null" && echo "$curlres";echo "$curlres"|jq .res -c|grep -q "null"|| (echo "$curlres"|jq .res -c|grep -v -e '": 0' -e '":0' |grep -v -e ^$ -e '^}$' -e '^{$' );echo ) |grep -v ^$ & 
  #echo "$loctr"| grep -q ^0$ || ( curlres=$(curl -s -H "API-KEY: $TSTOKEN" "${TSURL}" -H "Content-Type: application/json" -X POST  --data "${lojsonout}" );(echo "$curlres"|jq . &>/dev/null && (echo "$curlres"|jq .) ) || echo "$curlres";echo ) |grep -v ^$ & 
  echo -n "--" $loctr
  (echo "$loctr"|grep -q ^0$) || ( echo -n "↓..." ;curlres=$(curl -s -H "API-KEY: $TSTOKEN" "${TSURL}" -H "Content-Type: application/json" -X POST  --data "${lojsonout}" 2>&1  );(echo "$curlres";echo ) |grep -v ^$ )  & 
  (echo "$loctr"|grep -q ^0$) ||   sleep 0.4
  echo
  #echo "$hictr"| grep -q ^0$ || ( curlres=$(curl -s -H "API-KEY: $TSTOKEN" "${TSURL}" -H "Content-Type: application/json" -X POST  --data "${hijsonout}" );echo "$curlres"|jq . &>/dev/null || echo "$curlres";echo "$curlres"|jq .|grep -q "null" && echo "$curlres";echo "$curlres"|jq .res -c|grep -q "null"|| (echo "$curlres"|jq .res -c|grep -v -e '": 0' -e '":0' |grep -v -e ^$ -e '^}$' -e '^{$' );echo ) |grep -v ^$ &
  #echo "$hictr"| grep -q ^0$ || ( curlres=$(curl -s -H "API-KEY: $TSTOKEN" "${TSURL}" -H "Content-Type: application/json" -X POST  --data "${hijsonout}" );(echo "$curlres"|jq . &>/dev/null && (echo "$curlres"|jq .) ) || echo "$curlres";echo ) |grep -v ^$ & 
  echo -n "++" $hictr
  (echo "$hictr"|grep -q ^0$) || ( echo -n "↑..." ;curlres=$(curl -s -H "API-KEY: $TSTOKEN" "${TSURL}" -H "Content-Type: application/json" -X POST  --data "${hijsonout}" 2>&1  );(echo "$curlres";echo ) |grep -v ^$ ) & 
  (echo "$hictr"|grep -q ^0$) || ( curlres=$(curl -s -H "API-KEY: $TSTOKEN" "${TSURL}" -H "Content-Type: application/json" -X POST  --data "${hijsonout}" ); echo "$curlres";echo ) |grep -v ^$  & 
  [[ "$hictr" == 0 ]] || sleep 0.3
done  2>&1  )  2>&1 |sed 's/^/ADDURL:/g'   ;
timestamp=$(echo "$myhour" |sed 's/_/ /g;s/\./:/g;s/$/:59:59/g')
datestamp=$(date +%s -u -d "$timestamp")
echo "DONE W SENDING .. snapsotting : $SENT_SOMETHING"
[[ "$SENT_SOMETHING" == "true" ]] && { 
sleep 5;
mkfifo /tmp/rst.io &>/dev/null|| true 
cat /tmp/rst.io |sed 's/^/'"$myhour"'| ADD:/g' &
#echo restic backup --time "$timestamp" --host "$hostname" "$myhour/*.json
#     restic backup --time "$timestamp" --host "byhour" $myhour/*.json &> /tmp/rst.io 
restic backup --stdin-filename feeds_$myhour.tgz --time "$timestamp" --host "byhour_compressed" --stdin-from-command -- /bin/bash -c "tar cv $myhour/*.json | gzip --rsyncable -c "  &> /tmp/rst.io 

#  && ( echo "$myhour/$arch" >> "/tmp/.del_$myhour" )
restic forget --keep-hourly 2 --prune 2>&1|grep -e byhost -e  json |grep -v ^$|sed 's/^/'"$myhour"'| /g'

mkfifo /tmp/rst.io &>/dev/null|| true  

[[ "$SECREADY" == "true" ]] && {  echo CPY_SEC; export RESTIC_REPOSITORY="$SECRESTURL";export AWS_SECRET_ACCESS_KEY="$SECRESTSKY";export AWS_ACCESS_KEY_ID="$SECRESTACK" ; restic copy --from-repo /tmp/restic &> /tmp/rst.log ;  cat /tmp/rst.log 2>&1|grep -v ^$|sed 's/^/'"$myhour"'| SEC:/g' ;   } &
sleep 2
export RESTIC_REPOSITORY="$RESTURL";export AWS_SECRET_ACCESS_KEY="$RESTSKY";export AWS_ACCESS_KEY_ID="$RESTACK"
BACKUP_OK=false
cat /tmp/rst.io |sed 's/^/'"$myhour"'| PRI:/g' | tee /tmp/rst.out &
export |grep RESTIC|grep -v PASSWO
restic copy --from-repo /tmp/restic &> /tmp/rst.io 
wait
grep "saved$" /tmp/rst.out && BACKUP_OK=true 
echo "OK: $BACKUP_OK"
[[ "$BACKUP_OK" == "true" ]] && ( cmdlist=$(cat "/tmp/.del_$myhour" |sed 's/^/ rm /g;s/$/;/g') ; echo "COPY OK.. delete source "$(echo "$cmdlist"|grep rm |wc -l ) ;echo "open ""$DAVURL""feedarchive/;""$cmdlist"";quit" |lftp & cat "/tmp/.del_$myhour" |while read a ;do test -e "$a" && rm "$a"  ${a/\.gz/} ;done ;wait )   
#rm -rf /tmp/restic
test -e /tmp/restic || mkdir /tmp/restic
restic -r /tmp/restic init|| true
  echo -n ; } ;

test -e "/tmp/.del_$myhour" && rm "/tmp/.del_$myhour"

done

export RESTIC_REPOSITORY="$RESTURL";export AWS_SECRET_ACCESS_KEY="$RESTSKY";export AWS_ACCESS_KEY_ID="$RESTACK"
restic forget --keep-hourly 3 --prune 2>&1|grep -v ^$|sed 's/^/'"$myhour"'| PRI:/g'

[[ "$SECREADY" == "true" ]] && {  export RESTIC_REPOSITORY="$SECRESTURL";export AWS_SECRET_ACCESS_KEY="$SECRESTSKY";export AWS_ACCESS_KEY_ID="$SECRESTACK" ; restic forget --keep-hourly 3 --prune 2>&1|grep -v ^$|sed 's/^/'"$myhour"'| SEC:/g'  ; } ; 
