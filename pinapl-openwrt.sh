cd /root/pinapl

echo $2 > /sys/class/gpio/export 2>/dev/null
echo out >/sys/class/gpio/gpio$2/direction 2>/dev/null

while [ 1 == 1 ]; do
	
	logger -p user.info -t pinapl "Starting display"
	echo 1 > /sys/class/gpio/gpio$2/value
	sleep 5
	logger -p user.info -t pinapl "Starting $1"	
	./$1 > /tmp/pinapl.log 2>&1
	logger -p user.crit -t pinapl "`head -1 /tmp/pinapl.log`"
	echo 0 > /sys/class/gpio/gpio$2/value
 
done
