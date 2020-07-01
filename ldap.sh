function vault_curl() {
  curl -sk \
  ${CURL_VERBOSE:+"-v"} \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  --header "X-Vault-Namespace: ${VAULT_NAMESPACE}" \
  --cert   "$VAULT_CLIENT_CERT" \
  --key    "$VAULT_CLIENT_KEY" \
  --cacert "$VAULT_CACERT" \
  "$@"
}

function ldap() {

  echo -e "=======================================\n|				      |\n|        LDAP Authentication          |\n|				      |\n======================================="

  VAULT_NAMESPACE=$1
  NAMES=$(vault_curl \
    --request LIST \
    $VAULT_ADDR/v1/auth/ldap/users | \
    jq -r '.["data"]["keys"]'|grep \" )

  for name in $NAMES
  do
      [[ $name != 'null' ]] && [[ $name != ']' ]] && [[ $name != '[' ]] \
          && n=$(echo $name | sed -e s/'"'/''/g -e s/','/''/ ) \
          && echo -e "Username: $n\n Policies:" \
          && vault_curl $VAULT_ADDR/v1/auth/ldap/users/$n | jq .data.policies\
	
	for pol in $(vault_curl $VAULT_ADDR/v1/auth/ldap/users/$n | jq .data.policies|grep \"|sed -e 's/"//g' -e 's/,//g');
	do
		echo "Policy rights for $pol which is accessible for user $name:"	
		vault_curl $VAULT_ADDR/v1/sys/policy/$pol|jq '.data.rules'
	done
done

}
ldap
