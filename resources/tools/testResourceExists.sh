az config set extension.use_dynamic_install=yes_without_prompt

result=$(az resource show --ids $ResourceId 2> /dev/null)

jq -c --null-input \
	--argjson resourceExists $(if [ -z "$result" ]; then echo false; else echo true; fi) \
	--argjson resourceProperties "$([ -z "$result" ] && echo '{}' || echo $result | jq '.properties // {}')" \
	--argjson resourceTags "$([ -z "$result" ] && echo '{}' || echo $result | jq '.tags // {}')" \
	'{ resourceExists: $resourceExists, resourceProperties: $resourceProperties, resourceTags: $resourceTags }' > $AZ_SCRIPTS_OUTPUT_PATH