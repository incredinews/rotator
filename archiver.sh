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
#[[ -z "$RESTSEC"  ]] && exit 1
export RESTIC_REPOSITORY="$RESTURL";export AWS_SECRET_ACCESS_KEY="$RESTSKY";export AWS_ACCESS_KEY_ID="$RESTACK"
export SECREADY=true
[[ -z $SECRESTACK       ]] && export SECREADY=false
[[ -z $SECRESTSKY       ]] && export SECREADY=false
[[ -z $SECRESTURL ]] && export SECREADY=false

cd /tmp/
test -e /tmp/feedarch||mkdir /tmp/feedarch
cd /tmp/feedarch
test -e /tmp/restic || mkdir /tmp/restic
restic -r /tmp/restic init|| true
export RESTIC_REPOSITORY="$RESTURL";export AWS_SECRET_ACCESS_KEY="$RESTSKY";export AWS_ACCESS_KEY_ID="$RESTACK"
restic init || true
[[ "$SECREADY" = "true" ]] && {  export RESTIC_REPOSITORY="$SECRESTURL";export AWS_SECRET_ACCESS_KEY="$SECRESTSKY";export AWS_ACCESS_KEY_ID="$SECRESTACK" ; restic init || true  ; } ; 
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
test -e /tmp/.del_$myhour || touch "/tmp/.del_$myhour"
  for arch in $(ls "$myhour" -1|grep $feed|sort -n|grep gz);do 
  echo  "                                 "$( ls -1 "$myhour/$arch")" "$(du -k "$myhour/$arch"|cut -d" " -f1)" K"
  hostname=$(echo "$arch"|cut -d"_" -f1);
  timestamp=$(echo "$arch"|cut -d_ -f2-|cut -d"." -f1,2 |sed 's/_/ /g;s/\./:/g;s/$/:00/g');
  export RESTIC_HOST=$hostname
  
  links=$(cat "$myhour/$arch"|gunzip | tee "$myhour/"${arch/\.gz/} |jq .content|sed 's/\\n/\n/g'|grep "<link"|sed 's/\\"//g'|sed 's/link href=/link>/g'|cut -d">" -f2|cut -d"<" -f1 |sed 's/?ref=rss\///g' |grep -v ^$|grep -e ^ftp:// -e ^https:// -e ^http:// )
 grep -q "window._cf_chl_opt.cOgUHash" "$myhour/"${arch/\.gz/} || (echo "$links"|wc -l |grep -q -e ^0$ -e ^1$) ||  { 
  md5sum "$myhour/"${arch/\.gz/} 
  grep 'content' "$myhour/"${arch/\.gz/} -q && (echo "$myhour/$arch" >> "/tmp/.del_$myhour")
  grep 'content' "$myhour/"${arch/\.gz/} -q &&  export SENT_SOMETHING=true
  #mkfifo /tmp/rst.io &>/dev/null|| true 
  #cat /tmp/rst.io |sed 's/^/'"$myhour"'| ADD:/g' &
  ##echo restic backup --time "$timestamp" --host "$hostname" "$myhour/"${arch/\.gz/} 
  #     restic backup --time "$timestamp" --host "$hostname" "$myhour/"${arch/\.gz/} &> /tmp/rst.io  && ( echo "$myhour/$arch" >> "/tmp/.del_$myhour" )
  datestamp=$(date +%s -u -d "$timestamp")
  echo $timestamp " links: "$(echo "$links"|wc -l)
  ##                      batch n items for timestamp
  echo "$links"| xargs -P 1 -n 22|while read list;do 
    tsout='"ts": {';out='{"urls": [';for m in $list;do out="$out"'"'"$m"'",';tsout="$tsout"'"'"$m"'": '"$datestamp"',' ;done  
    jsonout=$(echo "$out"|sed 's/,$/],/g')$(echo "$tsout"|sed 's/,$/}/g')"}"  ;
    #echo "$jsonout"|jq . -c ;#echo "$jsonout"
    ( curl -s -H "API-KEY: $TSTOKEN" "${TSURL}" -H "Content-Type: application/json" -X POST  --data "${jsonout}"|jq .res|grep -v -e '": 0' -e '":0' |grep -v -e ^$ -e '^}$' -e '^{$' |sed 's/^/ADDURL:/g'   ;echo ) & sleep 0.5
  done ; } ;
  #test -e "$myhour/"${arch/\.gz/} && rm "$myhour/"${arch/\.gz/}
  
done;done
timestamp=$(echo "$myhour" |sed 's/_/ /g;s/\./:/g;s/$/:59:59/g')
datestamp=$(date +%s -u -d "$timestamp")

[[ "$SENT_SOMETHING" = "true" ]] && { 
sleep 5;
mkfifo /tmp/rst.io &>/dev/null|| true 
cat /tmp/rst.io |sed 's/^/'"$myhour"'| ADD:/g' &
#echo restic backup --time "$timestamp" --host "$hostname" "$myhour/*.json
     restic backup --time "$timestamp" --host "byhour" $myhour/*.json &> /tmp/rst.io 
#  && ( echo "$myhour/$arch" >> "/tmp/.del_$myhour" )
restic forget --keep-hourly 2 --prune 2>&1|grep -e byhost -e  json |grep -v ^$|sed 's/^/'"$myhour"'| /g'

mkfifo /tmp/rst.io &>/dev/null|| true  

[[ "$SECREADY" = "true" ]] && {  export RESTIC_REPOSITORY="$SECRESTURL";export AWS_SECRET_ACCESS_KEY="$SECRESTSKY";export AWS_ACCESS_KEY_ID="$SECRESTACK" ; restic copy --from-repo /tmp/restic &> /tmp/rst.log ;  cat /tmp/rst.log 2>&1|grep -v ^$|sed 's/^/'"$myhour"'| SEC:/g' ;   } &
sleep 2
export RESTIC_REPOSITORY="$RESTURL";export AWS_SECRET_ACCESS_KEY="$RESTSKY";export AWS_ACCESS_KEY_ID="$RESTACK"
BACKUP_OK=false
cat /tmp/rst.io |sed 's/^/'"$myhour"'| PRI:/g' | tee /tmp/rst.out &
restic copy --from-repo /tmp/restic &> /tmp/rst.io 
wait
grep "DONE" /tmp/rst.out && BACKUP_OK=true 
echo "OK: $BACKUP_OK"
#[[ "$BACKUP_OK" = "true" ]] && ( cmdlist=$(cat "/tmp/.del_$myhour" |sed 's/^/ rm /g;s/$/;/g') ; echo "COPY OK.. delete source "$(echo "$cmdlist"|grep rm |wc -l ) ;echo "open ""$DAVURL""feedarchive/;""$cmdlist"";quit" |lftp & cat "/tmp/.del_$myhour" |while read a ;do test -e "$a" && rm "$a"  ${a/\.gz/} ;done ;wait )   
#rm -rf /tmp/restic
test -e /tmp/restic || mkdir /tmp/restic
restic -r /tmp/restic init|| true
  echo -n ; } ;

test -e "/tmp/.del_$myhour" && rm "/tmp/.del_$myhour"

done

export RESTIC_REPOSITORY="$RESTURL";export AWS_SECRET_ACCESS_KEY="$RESTSKY";export AWS_ACCESS_KEY_ID="$RESTACK"
restic forget --keep-hourly 3 --prune 2>&1|grep -v ^$|sed 's/^/'"$myhour"'| PRI:/g'

[[ "$SECREADY" = "true" ]] && {  export RESTIC_REPOSITORY="$SECRESTURL";export AWS_SECRET_ACCESS_KEY="$SECRESTSKY";export AWS_ACCESS_KEY_ID="$SECRESTACK" ; restic forget --keep-hourly 3 --prune 2>&1|grep -v ^$|sed 's/^/'"$myhour"'| SEC:/g'  ; } ; 
