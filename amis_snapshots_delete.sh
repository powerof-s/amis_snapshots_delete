# Substract 20 and 10 days from today

echo "***********************************"
tendays="$(date -v-10d +%Y-%m-%d)"
echo "Today - 10 days is ${tendays}"

twentydays="$(date -v-20d +%Y-%m)"
echo "Year and month of  - 20 days is ${twentydays}"

echo "***********************************"

# List regions
for region in `aws ec2 describe-regions --all-regions --query "Regions[].{Name:RegionName}" --output text --profile <profile name>`
do

# Pull the list of AMIs
amis_to_delete=$(aws ec2 describe-images --region $region --owners 746615017976 --query "Images[?CreationDate<='$tendays'].ImageId" --output text --profile <profile name>)
echo "List of AMIs to delete: ${amis_to_delete} for region ${region}"
echo "***********************************"

# Pull the list of Snapshots
snapshots_to_delete=$(aws ec2 describe-snapshots --region $region --owner-ids 746615017976 --query "Snapshots[?StartTime<='$tendays'].SnapshotId" --output text --profile <profile name>)
echo "List of Snapshots to delete: ${snapshots_to_delete} for region ${region}"
echo "***********************************"

# Pull the list of EC2 Volumes
#volumes_to_delete=$(aws ec2 describe-volumes --region $region --query "Volumes[*].{VolumeID:VolumeId,State:State}" --output text --profile <profile name> | grep -E '(available)' | awk '{print $2}')

volumes_to_delete=$(aws ec2 describe-volumes --region us-east-1 --query "Volumes[*].{VolumeID:VolumeId,State:State,CreateTime:CreateTime}" --output text --profile <profile name> | grep -v '$twentydays' | awk '{print $3}')
echo "List of EC2 volumes to delete that are not in use: ${volumes_to_delete} for region ${region}"
echo "***********************************"


# Unused Volume actual deletion
for volume in $volumes_to_delete; do
aws ec2 detach-volume --volume-id $volumes_to_delete --region $region --profile <profile name>
aws ec2 delete-volume --volume-id $volumes_to_delete --region $region --profile <profile name>
echo "Deleting Unused volume - ${volume} in ${region}"
echo "***********************************"
done

# AMIs actual deletion
for ami in $amis_to_delete; do
  aws ec2 deregister-image --image-id $ami --region $region --profile <profile name>
echo "Deleting AMI - ${ami} in ${region}"
echo "***********************************"
done

# Snapshots actual deletion
for snap in $snapshots_to_delete; do
 aws ec2 delete-snapshot --snapshot-id $snap --region $region --profile <profile name>
echo "Deleting Snapshots - ${snap} in ${region}"
echo "***********************************"
done


done
