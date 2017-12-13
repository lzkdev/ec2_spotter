# settings
export name="fast-ai"
export keyName="aws-key-$name"
export maxPricePerHour=0.2

# Set current dir to working dir - http://stackoverflow.com/a/10348989/277871
cd "$(dirname ${BASH_SOURCE[0]})"

# By default it's empty
instance_id=
# Read the input args
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --instance_id)
    instance_id="$2"
    shift # pass argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # pass argument or value
done

# Find the instance id by the instance name (if there are two instances with same name, use the first one)
if [ "x$instance_id" = "x" ]
then
	# Get the instance by name.
	export instanceId=`aws ec2 describe-instances --filters Name=tag:Name,Values=$name-gpu-machine --output text --query 'Reservations[*].Instances[0].InstanceId'`
else
	# We have passed an instance id
	instanceId=$instance_id
fi

# By default, AWS will delete this volume if the instance is terminated. 
# We need this volume for the spot instance, so let's fix this.
aws ec2 modify-instance-attribute --instance-id $instanceId --block-device-mappings "[{\"DeviceName\": \"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":false}}]"

# Get the volume of the instance
export volumeId=`aws ec2 describe-instances --instance-ids $instanceId --output text --query 'Reservations[*].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId'`

# name the volume of this instance
aws ec2 create-tags --resources $volumeId --tags Key=Name,Value="${name}-volume"

# Get the Elastic IP id
export ip=`aws ec2 describe-instances --instance-ids $instanceId --output text --query 'Reservations[*].Instances[0].NetworkInterfaces[0].Association.PublicIp'`
# Supress errors if this is not an elastic ip
export elasticId=`aws ec2 describe-addresses --public-ips $ip --output text --query 'Addresses[0].AllocationId' 2>/dev/null`
# We want empty elastic id if not present, not None
if [ "$elasticId" = "None" ] 
then
	export elasticId=
fi

# Get the security group of the instance
export securityGroup=`aws ec2 describe-instances --instance-ids $instanceId --output text --query 'Reservations[*].Instances[0].SecurityGroups[0].GroupId'`

# The zone where the instance and the volume are. Needed to launch the spot instance.
export zone=`aws ec2 describe-instances --instance-ids $instanceId --output text --query 'Reservations[*].Instances[0].Placement.AvailabilityZone'`
# The subnet of the instance. Needed to launch the spot instance.
export subnet=`aws ec2 describe-instances --instance-ids $instanceId --output text --query 'Reservations[*].Instances[0].SubnetId'`

# Terminate the on-demand instance
aws ec2 terminate-instances --instance-ids $instanceId

# wait until the volume is available
echo 'Waiting for volume to become available.'
aws ec2 wait volume-available --volume-ids $volumeId

export region=`aws configure get region`
# The ami to boot up the spot instance with.
# Ubuntu-xenial-16.04 in diff regions.
# Ubuntu 16.04.1 LTS
if [ $region = "us-west-1" ]; then 
	export ami=ami-1812bb61 # 加利福尼亚北部
elif [ $region = "eu-west-2" ]; then 
	export ami=ami-f1e73689 # 俄勒冈
elif [ $region = "us-east-1" ]; then
  	export ami=ami-405ade3a # 弗吉尼亚北部
elif [ $region = "us-east-2" ]; then
  	export ami=ami-f0725c95 # 俄亥俄州
elif [ $region = "ap-southeast-2" ]; then
  	export ami=ami-5603eb34 # 悉尼
elif [ $region = "ap-northeast-1" ]; then
  	export ami=ami-329c2b54 # 东京
elif [ $region = "ap-northeast-2" ]; then
  	export ami=ami-0ce14662 # 首尔
fi
echo 'If you are using Amazon Deep Learning AMI, do not forget to change parameter ec2spotter_preboot_image_id in ../my.conf , otherwise the root swap script will fail!'

# Get the scripts that will perform the swap from github
# Switch to --branch stable eventually.
export config_file=../my.conf

# Create the ec2 spotter file
cat > $config_file <<EOL
# Name of root volume.
ec2spotter_volume_name=${name}-volume
# Location (zone) of root volume. If not the same as ec2spotter_launch_zone, 
# a copy will be created in ec2spotter_launch_zone.
# Can be left blank, if the same as ec2spotter_launch_zone
ec2spotter_volume_zone=$zone

ec2spotter_launch_zone=$zone
ec2spotter_key_name=$keyName
ec2spotter_instance_type=p2.xlarge
# Some instance types require a subnet to be specified:
ec2spotter_subnet=$subnet

ec2spotter_bid_price=$maxPricePerHour
# uncomment and update the value if you want an Elastic IP
ec2spotter_elastic_ip=$elasticId

# Security group
ec2spotter_security_group=$securityGroup

# The AMI to be used as the pre-boot environment. This is NOT your target system installation.
# Do Not Modify this unless you have a need for a different Kernel version from what's supplied.
ec2spotter_preboot_image_id=$ami
EOL

echo All done, you can start your spot instance with: sh start_spot.sh
