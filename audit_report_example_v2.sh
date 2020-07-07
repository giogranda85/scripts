#!/bin/bash
echo "Vault address: ${VAULT_ADDR}"

#Setting colors for output
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

# Set namespace to root if nothing
VAULT_NAMESPACE=${VAULT_NAMESPACE:-"root/"}
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

#print userpass auth information
function userpass() {

  echo -e "${red}=======================================\n         Namespace= $1                             \n         Auth Mount Point: $2       \n                                     \n=======================================${reset}"
  #VAULT_NAMESPACE=$1
  echo "Displaying users from auth mount point  \"$2\":"
  NAMES=$(vault_curl \
    --request LIST \
    $VAULT_ADDR/v1/auth/$2/users | \
    jq -r '.["data"]["keys"]')
  [[ $NAMES != 'null' ]]
  for name in $NAMES
  do
      [[ $name != 'null' ]] && [[ $name != ']' ]] && [[ $name != '[' ]] \
          && n=$(echo $name | sed -e s/'"'/''/g -e s/','/''/ ) \
          && echo -e "Username: $n\n Policies:" \
          && vault_curl $VAULT_ADDR/v1/auth/$2/users/$n | jq .data.policies
  done

token_accessor $2

}

#print token auth information
function token(){
  echo -e "${red}=======================================\n         Namespace= $1                              \n         Auth Mount Point: $2        \n                                     \n=======================================${reset}"

token_accessor $2

}

#print ldap auth information
function ldap() {

  echo -e "${red}=======================================\n         Namespace= $1		      \n         Auth Mount Point: $2          \n				      \n=======================================${reset}"

  #VAULT_NAMESPACE=$1
  NAMES=$(vault_curl \
    --request LIST \
    $VAULT_ADDR/v1/auth/$2/users | \
    jq -r '.["data"]["keys"]'|grep \" )

  for name in $NAMES
  do
      [[ $name != 'null' ]] && [[ $name != ']' ]] && [[ $name != '[' ]] \
          && n=$(echo $name | sed -e s/'"'/''/g -e s/','/''/ ) \
          && echo -e "Username: $n\n Policies:" \
          && vault_curl $VAULT_ADDR/v1/auth/$2/users/$n | jq .data.policies\
	
done

token_accessor $2

}
#print approle auth information
function approle() {

  echo -e "${red}=======================================\n         Namespace= $1              \n         Auth Mount Point: $2        \n                                     \n=======================================${reset}"
  
  echo "Available roles within Approle Authentication:"
  #VAULT_NAMESPACE=$1
  NAMES=$(vault_curl \
    --request LIST \
    $VAULT_ADDR/v1/auth/$2/role | \
    jq -r '.["data"]["keys"]')
  [[ $NAMES != 'null' ]]
  for name in $NAMES
  do
      [[ $name != 'null' ]] && [[ $name != ']' ]] && [[ $name != '[' ]] \
          && n=$(echo $name | sed -e s/'"'/''/g -e s/','/''/ ) \
          && echo -e "Username: $n" \
          && vault_curl $VAULT_ADDR/v1/auth/$2/role/$n | jq '"Policies:",.data.token_policies,"Secret ID Number of uses limit:",.data.secret_id_num_uses, "Secret ID TTL (sec):", .data.secret_id_num_uses'

done


#Active Tokens for approle

token_accessor $2

}

#Check for accessors based on the passed in auth method
function token_accessor() {
#VAULT_NAMESPACE=$1
#echo "NAMESPACE NAME=$1"
echo -e "\nScanning for active token accessors created via $1 authentication\n"
i=0
  ACCESSOR_RAW=$(vault_curl \
   --request LIST \
   $VAULT_ADDR/v1/auth/token/accessors
  )

    for accessor in $(echo $ACCESSOR_RAW | jq -r '.? | .["data"]["keys"] | join("\n")');
    do  
        displayname="$(vault_curl --request POST -d "{ \"accessor\": \"${accessor}\" }" \
        $VAULT_ADDR/v1/auth/token/lookup-accessor | jq '.data.display_name'|sed 's/"//g' )"  
        meta="$(vault_curl --request POST -d "{ \"accessor\": \"${accessor}\" }" \
        $VAULT_ADDR/v1/auth/token/lookup-accessor | jq '.data.meta'|sed -e 's/"//g' -e 's/{//g' -e 's/}//g'| grep -v null)"
	policy="$(vault_curl --request POST -d "{ \"accessor\": \"${accessor}\" }" \
        $VAULT_ADDR/v1/auth/token/lookup-accessor | jq '.data.policies'|grep \"|sed -e 's/"//g' -e 's/,//g')"

	#checking for userpass
	if echo "$displayname" | grep -q userpass;
	then
		tmp=$(echo "$displayname"|cut -d\- -f1)
		displayname=$tmp	
	fi        
 
        #checking accessors against requested type
        if [[ "$displayname" = "$1" ]]; 
        then
	
                echo -e "\n==============\nActive $1 accessor: $accessor  $meta \n\n Policies: ${red}\n$policy\n${reset}"
                i=$((i+1))
		meta=""
        	for pol in $(echo $policy)
        	do
                	echo "Privilege from policy ${red}\"$pol\"${reset} assigned to accessor: $accessor"       
               	echo -e "${green}$(vault_curl $VAULT_ADDR/v1/sys/policy/$pol|jq '.data.rules')${reset}\n"
        	
		done
        fi  
    done
        if [[ $i == 0 ]]; 
        then
                echo "No active $1 accessors available"
        fi  
}

#scan for enabled auth methods within passed in namespace
function findmountpoint() {
VAULT_NAMESPACE=$1
for mounted in $(vault_curl --request GET $VAULT_ADDR/v1/sys/auth|jq '.data | keys' |grep \"|cut -d\" -f2|sed 's/\///');
	do 
        if echo "$mounted"|grep -q userpass
	then
        	userpass $1 $mounted
	elif echo "$mounted"|grep -q ldap
	then
		ldap $1 $mounted
	elif echo "$mounted"|grep -q token
	then
		token $1 $mounted
	elif echo "$mounted"|grep -q approle
	then
		approle $1 $mounted
		
	fi

done

}

#Uncalled function for now
function print_things() {
  VAULT_NAMESPACE=$1
  NAMES=$(vault_curl \
    --request LIST \
    $VAULT_ADDR/v1/identity/entity/name | \
    jq -r '.["data"]["keys"]')
  [[ $NAMES != 'null' ]] && echo "Entity names: $NAMES"
  for name in $NAMES
  do
      [[ $name != 'null' ]] && [[ $name != ']' ]] && [[ $name != '[' ]] \
          && n=$(echo $name | sed -e s/'"'/''/g -e s/','/''/ ) \
          && echo "Printing entity with name: $n" \
          && vault_curl $VAULT_ADDR/v1/identity/entity/name/$n | jq .
  done
  AUTH_METHODS=$(vault_curl $VAULT_ADDR/v1/sys/auth | jq '.["data"] | keys[]' | tr -d '\n' | sed s/'\/"'/'\/",'/g)
  echo "Auth Methods: [$AUTH_METHODS]"
  
  # Roles
  TOTAL_ROLES=0
  for mount in $(vault_curl \
   $VAULT_ADDR/v1/sys/auth | \
   jq -r '.? | .["data"] | keys[]');
  do
     users=$(vault_curl \
     --request LIST \
     $VAULT_ADDR/v1/auth/${mount}users | \
               jq -r '.["data"]["keys"]')
    [[ ! -z $users ]] && [[ $users != 'null' ]]  && echo "Users for mount $mount: $users"
   
   roles=$(vault_curl \
     --request LIST \
     $VAULT_ADDR/v1/auth/${mount}roles | \
     jq -r '.["data"]["keys"]')
    [[ ! -z $roles ]] && [[ $roles != 'null' ]]  && echo "Roles for mount $mount: $roles"

  done

  # Tokens
  TOTAL_TOKENS_RAW=$(vault_curl \
   --request LIST \
   $VAULT_ADDR/v1/auth/token/accessors
  )
    for accessor in $(echo $TOTAL_TOKENS_RAW | jq -r '.? | .["data"]["keys"] | join("\n")');
    do
        if [[ $PRINT_TOKEN_META = 1 ]]; then
           token=$(vault_curl --request POST -d "{ \"accessor\": \"${accessor}\" }" \
             $VAULT_ADDR/v1/auth/token/lookup-accessor | jq '.data' ) && echo "Token accessor $accessor: $token"
        else
            echo "Token accessor $accessor: skip printing metadata (set PRINT_TOKEN_META=1)"
        fi
    done      
}

#Uncalled function for now
function count_things() {
  VAULT_NAMESPACE=$1
  TOTAL_ENTITIES=$(vault_curl \
    --request LIST \
    $VAULT_ADDR/v1/identity/entity/id | \
    jq -r '.? | .["data"]["keys"] | length')
  # Roles
  TOTAL_ROLES=0
  for mount in $(vault_curl \
   $VAULT_ADDR/v1/sys/auth | \
   jq -r '.? | .["data"] | keys[]');
  do
   users=$(vault_curl \
     --request LIST \
     $VAULT_ADDR/v1/auth/${mount}users | \
     jq -r '.? | .["data"]["keys"] | length')
   roles=$(vault_curl \
     --request LIST \
     $VAULT_ADDR/v1/auth/${mount}roles | \
     jq -r '.? | .["data"]["keys"] | length')
   TOTAL_ROLES=$((TOTAL_ROLES + users + roles))
  done
  # Tokens
  TOTAL_TOKENS_RAW=$(vault_curl \
   --request LIST \
   $VAULT_ADDR/v1/auth/token/accessors
  )
  TOTAL_TOKENS=$(echo $TOTAL_TOKENS_RAW | jq -r '.? | .["data"]["keys"] | length')
  TOTAL_ORPHAN_TOKENS=0
  for accessor in $(echo $TOTAL_TOKENS_RAW | \
   jq -r '.? | .["data"]["keys"] | join("\n")');
  do
   token=$(vault_curl \
     --request POST \
     -d "{ \"accessor\": \"${accessor}\" }" \
     $VAULT_ADDR/v1/auth/token/lookup-accessor | \
     jq -r '.? | .| [select(.data.path == "auth/token/create")] | length')
   TOTAL_ORPHAN_TOKENS=$((TOTAL_ORPHAN_TOKENS + $token))
  done
  echo "$TOTAL_ENTITIES,$TOTAL_ROLES,$TOTAL_TOKENS,$TOTAL_ORPHAN_TOKENS"
}
#uncalled function for now
function output() {
  # Transform comma-separated list into output
  array=($(echo $1 | sed 's/,/ /g'))
  echo "Total entities: ${array[0]}"
  echo "Total users/roles: ${array[1]}"
  echo "Total tokens: ${array[2]}"
  echo "Total orphan tokens: ${array[3]}"
}


function main() {
  # Run counts where we stand
  #VAULT_NAMESPACE=$1
  echo "Namespace: $VAULT_NAMESPACE"
  counts=$(count_things $VAULT_NAMESPACE)
  output $counts
  print_things $VAULT_NAMESPACE
  
  #Call to finding finding all auth methods in root namespace
  findmountpoint $VAULT_NAMESPACE
  
  # Pull all namespaces from current position, if any
  NAMESPACE_LIST=$(vault_curl \
    --request LIST \
    $VAULT_ADDR/v1/sys/namespaces | \
    jq .data.keys|grep \"|cut -d\" -f2|sed 's/\///')
  
  if [ ! -z "$NAMESPACE_LIST" ]
  then
    for ns in $NAMESPACE_LIST; do
	#echo "================== DUMPING NAMESPACE $ns ==================="
  	echo "Namespace: $ns"
  	counts=$(count_things $ns)
  	output $counts
  	print_things $ns
	findmountpoint $ns
    done
  fi
}

main
