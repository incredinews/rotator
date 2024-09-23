echo "Loading"

mkdir ./app;
cp *.sh *.py ./app
sed 's/HOST_NAME/'"${LOKI_HOST}"'/g' -i fluent.conf
sed 's/USER_NAME/'"${LOKI_USER}"'/g' -i fluent.conf
sed   's/API_KEY/'"${LOKI_TOKN}"'/g' -i fluent.conf

docker-compose up -d 

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
