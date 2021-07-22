registry=kubernetes.docker.internal
credentials=admin:bitnami

catalog=`curl -s -u "$credentials" http://$registry/v2/_catalog | jq 'flatten' | jq -r -c '.[]'`

for item in $catalog;
do
  url=http://$registry/v2/$item/tags/list
  taglist=`curl -s -u "$credentials" $url`
  tags=`echo $taglist | jq -r '.tags' | jq -r -c '.[]'`

  for tag in $tags
  do
    echo echo $registry/$item:$tag
    echo curl -s --data-raw \'{\"registry\": \"$registry\", \"image_name\": \"$item\", \"tag\": \"$tag\"}\' --location --request POST \'localhost:8080/v1/scan\' --header \'Content-Type: application/json\'
  done
done
