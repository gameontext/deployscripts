echo 'checking for ip'

publicIp=`cat public-ip.txt`
firstRun="false"
myuname="bapliam"
mytag="gojava"
outfile="deployOutput.txt"

if [[ $publicIp == "" ]]
then
	echo "empty" >> public-ip.txt
	publicIp="empty"
fi

if [[ $publicIp == "empty" ]]
then
 	firstRun="true"
	echo 'optaining  a public ip address from Bluemix'	
	publicIp=`cf ic ip request`
	for word in $publicIp
	do	
		if [[ $word =~ "." ]]
		then
			echo 'able to find octets'
			#to strip off the double quotes:
			publicIp=`echo "$word" | sed s/\"//g`
			break
		fi		
	done
	echo "$publicIp" > public-ip.txt
fi

if [[ $firstRun != "true" ]]
then

	echo 'obtaining group id' | tee  $outfile
	grpId=`cf ic ip list | grep "-"`
	for word in $grpId
	do
		grpId=$word
		if [[ $grpId =~ "-" ]]
		then 
			echo "group id: $grpId" | tee >> $outfile
			break
		fi
	done

	echo 'trying to unbind ip'
	cf ic ip unbind $publicIp $grpId

	echo 'cleaning up old image and container'
	img=`cf ic images | grep $mytag`	
	for word in $img
	do
		img=$word
		echo "image: $img" | tee >> $outfile
		break
	done
	echo "removing image $img"
	cf ic rmi $img
	
	ctnr=""
	ctnrs=`cf ic ps | grep $mytag`
	for word in $ctnrs
	do
		ctnr=$word
		echo "container id: $ctnr" | tee >> $outfile
		break
	done
	echo 'stopping and deleting current container'
	cf ic stop $ctnr
	cf ic rm $ctnr
fi

cf ic build -t $mytag .

img=`cf ic images | grep $mytag`
for word in $img
do
	img=$word
	break
done

echo "using image $img"
cf ic run -p 9080 --name $mytag $img

echo "using public ip: $publicIp to bind"
cf ic ip bind $publicIp $mytag

echo 'end of script'


