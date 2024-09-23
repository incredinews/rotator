echo "Loading"

mkdir ./app;
test -e app/logs|| mkdir app/logs

chmod a+r app/logs 
touch app/logs/{pages,curl,fetch,main}.log

cp *.sh *.py ./app
sed 's/HOST_NAME/'"${LOKI_HOST}"'/g' -i fluent-conf/fluent-bit.conf
sed 's/USER_NAME/'"${LOKI_USER}"'/g' -i fluent-conf/fluent-bit.conf
sed   's/API_KEY/'"${LOKI_TOKN}"'/g' -i fluent-conf/fluent-bit.conf
ls -1
docker-compose config 
docker compose up &

test -e cache && mv cache app/
(
cd ./app
time bash run.sh
for target in logs cache;do 
test -e "$target" && mv $target ..
done
)
time sync
exit 0
