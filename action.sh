echo "Loading"

mkdir ./app;
cp *.sh *.py ./app
test -e cache && mv cache app/
(
cd ./app
time bash run.sh
for target in logs cache;do 
test -e "$target" && mv $target ..
)
time sync
exit 0
