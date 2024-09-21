echo "Loading"

mkdir /app;
cp *.sh *.py /app
cd /app
time bash run.sh

time sync
exit 0
