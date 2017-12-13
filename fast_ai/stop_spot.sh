export config_file=spotinfo.tmp

i=0
for line in `cat $config_file`
do 
	if [ $i -eq 0 ]; then 
		export request_id=${line}
	elif [ $i -eq 1 ]; then 
		export instance_id=${line}
	fi
	i=1
done

echo Spot request ID: $request_id
echo Spot instance ID: $instance_id 

echo 'cancel spot instance' $request_id
aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $request_id
echo 'terminate instances' $instance_id
aws ec2 terminate-instances --instance-ids $instance_id
echo Waiting for ec2 instance to terminated...
aws ec2 wait instance-terminated --instance-ids $instance_id

# Clean up
rm $config_file

