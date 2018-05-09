PROJECT_ID=""
USER_NAME=""

cecho() {

	declare -A colors
	colors=(
		['black']='\E[0;47m'
		['red']='\E[0;31m'
		['green']='\E[0;32m'
		['yellow']='\E[0;33m'
		['blue']='\E[0;34m'
		['magenta']='\E[0;35m'
		['cyan']='\E[0;36m'
		['white']='\E[0;37m'
	)

	local defaultMSG="No message passed."
	local defaultColor="black"
	local defaultNewLine=true

	while [[ $# -gt 1 ]]; do
		key="$1"

		case $key in
		-c | --color)
			color="$2"
			shift
			;;
		-n | --noline)
			newLine=false
			;;
		*)
			# unknown option
			;;
		esac
		shift
	done

	message=${1:-$defaultMSG}
	color=${color:-$defaultColor}
	newLine=${newLine:-$defaultNewLine}

	echo -en "${colors[$color]}"
	echo -en "$message"
	if [ "$newLine" = true ]; then
		echo
	fi
	tput sgr0

	return
}

warning() {

	cecho -c 'yellow' "$1"
	log_debug "warning" "$1" "$2"

}

error() {

	cecho -c 'red' "$1"
	log_debug "error" "$1" "$2"
	exit

}

information() {

	cecho -c 'blue' "$1"
	log_debug "info" "$1" "$2"
}


success() {

	cecho -c 'green' "$1"
	log_debug "success" "$1" "$2"
}
is_true() {

	if [ "$1" = true ] || [ "$1" = "true" ] || [ "$1" = "1" ] || [ "$1" = 1 ]; then

		return 0
	fi
	return 1

}
is_debug() {
	return $(is_true $DEBUG)
}

log_debug() {
	msg=""
	if [ -z "$2" ]; then
		return
	fi

	if is_debug; then
		msg="($1)==> $2"
	fi
	if [ ! -z "$3" ]; then

		msg="$msg: $3"
	fi
	echo $msg >>$LOG_FILE
}
found_compute_key_file()
{
    if [ ! -e "$COMPUTE_KEY_FILE" ]; then
        error "Google compute key file not found in current directory: $COMPUTE_KEY_FILE" 
    fi
}
auth() {

    
    found_compute_key_file

	readonly PROJECT_ID=$(cat $COMPUTE_KEY_FILE | jq -r '.project_id')
	if [ "$PROJECT_ID" == "null" ]; then
		error "Unable to get project id"
		exit
	fi
	information "Authenticating" $PROJECT_ID
	#ret=$(gcloud auth activate-service-account --key-file $KEY_FILE    --project $PROJECT_ID 2>&1)
	ret=$(gcloud auth activate-service-account --key-file $COMPUTE_KEY_FILE --project $PROJECT_ID 2>&1)

	authenticated=$(echo $ret | grep "Activated service account")
	if [ -z "$authenticated" ]; then

		error "Unable to authenticate" $ret
		exit

	fi
	information "Authenticated"

	#echo $authenticated
}
rand_word() {

	shuf -n 1 /usr/share/dict/british-english | sed 's/./\u&/' | tr -d "\n'" | tr '[:upper:]' '[:lower:]'
}
print_array() {
	arr=$1
	#printf '%s\n' "${arr[@]}"
	(
 		echo "${arr[*]}"
	)

}

ssh_key_part() {
	if is_true "$WITH_SSH_KEYS"; then
		SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
        if [ ! -e "$SSH_KEY_FILE" ]; then
            error "SSH Key file not found: $SSH_KEY_FILE"
        fi
		SSH_KEY=$(cat $SSH_KEY_FILE)
		#echo $SSH_KEY
		if [ -z "SSH_KEY" ]; then
			error "Unable to open ssh key file $SSH_KEY_FILE"
		fi
		SSH_KEY=($SSH_KEY)
       
		#IFS=" " read -a ns <<< "${SSH_KEY}"
		#ns=$(printf -- "-%s" "${ns[@]}")
		#print_array $ns
		#SSH_KEY= ${SSH_KEY[1]}
		USER=${SSH_KEY[2]}
		SSH_KEY=${SSH_KEY[1]}
		IFS="@" read -a USER_NAME <<<"${USER}"
		USER_NAME=${USER_NAME[0]}
		FIND="+"
		REPLACE='\+'
		#SSH_KEY= $($SSH_KEY//$FIND/$REPLACE)
		#SSH_KEY= ${SSH_KEY//$FIND/$REPLACE}

		#SSH_KEY=$(replace_with "+" '\+' $SSH_KEY)
         

		#SSH_KEY=",ssh-keys=$USER_NAME:ssh-rsa $SSH_KEY $USER"
		#SSH_KEY=$(replace_with '"' '\"' "$SSH_KEY")
		#SSH_KEY=$(replace_with '&' '\&' "$SSH_KEY")
		#SSH_KEY=$(replace_with " " '\ ' "$SSH_KEY")
		#SSH_KEY=$(replace_with '|' '\|' "$SSH_KEY")
        
		#SSH_KEY=$(replace_with '+' '\+' "$SSH_KEY")
		echo "{\"user\":\"$USER\",\"user_name\":\"$USER_NAME\",\"ssh_key\":\"$SSH_KEY\"}"
	fi
}
replace_with() {
	echo ${3//$1/$2}

}

trim_this() {
	echo "$1" | xargs -0
}
strindex() {
	x="${1%%$2*}"
	[[ "$x" == "$1" ]] && echo -1 || echo "${#x}"
}
url_has_status()
{
     status=""
    content=$(wget --tries=1 --timeout=3 -S --spider "$1" 2>&1 | grep "HTTP/" | awk '{print $2}')
    content=(${content//\n/ })

    if [[ " ${content[@]} " =~ " ${2} " ]]; then
        return 0
    fi
    return 1
    if [ ${#content[@]} -gt 0 ];then 
        status=${content[${#content[@]}-1]} 
        echo $status
    fi
} 
sha1_pass()
{
    
     
    salt=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12 ; echo '')
    #echo "$salt--$1"
    #password=$(echo -n "$salt$1" | openssl dgst -sha1)
    password=$(echo -n "$1$salt" | openssl dgst -sha1 |awk '{print $NF}')
    echo "sha1:$salt:$password"

}
sha1_pass2()
{
    salt_len=12
    s=$(printf '%%0';printf $salt_len; printf "x" )
   
    r=$(od -N 6 -t uL -An /dev/urandom | tr -d " ") 
    salt=$(echo "obase=16;$r" | bc)
 
    echo $salt
    exit;
    salt=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12 ; echo '')
    #echo "$salt--$1"
    #password=$(echo -n "$salt$1" | openssl dgst -sha1)
    password=$(echo -n "$salt$1" | openssl dgst -sha1 |awk '{print $NF}')
    echo "sha1:$salt:$password"

}
wait_for_vm() {
	#sleep 1
    loop=0
    #information "waiting for vm to be up.. (1)" 

while :
do
    if [ $loop -ge 20 ];then
        return 1
    elif  url_has_status "$1" "404"  ;then
        return 0
    else
       ((loop++))
        information "waiting for vm to be up.. ($loop)"
        sleep 3
    fi    
done

    
     
	 
}
create_vm() {
	#"$SSH_USER" "$SSH_USER_NAME" "$SSH_KEY" "$PROJECT_ID"  "$(rand_word)" "pass"

	SSH_KEY_STR=""
	PROJECT=$4
	INSTANCE_NAME=$5
	#INSTANCE_NAME="casting"
	INSTANCE_NAME=$(trim_this "$INSTANCE_NAME")
    PASSWORD=$6
    #OLD_DOCKER="instance-2"
    OLD_DOCKER="unruffled_khorana"
    NEW_DOCKER="datascience"

    #DOCKER_IMAGE="docker-image"
    DOCKER_IMAGE="data-science-vm-docker-image"

    if [ -z "$PASSWORD" ];then

        
        read -s -p "Please a enter a password for your jupyter instance, Or leave blank to auto generate : " PASSWORD
        echo
        
        if [ -z "$PASSWORD" ];then
            PASSWORD=$(rand_word;printf "_";rand_word)
        fi
    fi

    PASS=$(sha1_pass "$PASSWORD")
    #echo "$PASSWORD==>$PASS" 
	COMMAND="sudo docker container kill $OLD_DOCKER ;
    sudo docker container rm  datascience;
    sudo docker run --name \"$NEW_DOCKER\" -d -p 8888:8888 jupyter/datascience-notebook start-notebook.sh --NotebookApp.password='$PASS';  
    
    echo 'sudo docker exec -i -t datascience /bin/bash' | sudo tee --append /etc/profile ;
     echo 'done';"
    #echo $COMMAND
    #COMMAND=""
    #COMMAND=""
#sudo docker container kill unruffled_khorana
#sudo docker container kill datascience
 #sudo docker run -d --name "datascience" -p 8888:8888 jupyter/datascience-notebook start-notebook.sh --NotebookApp.token="sha1:BBYDTNUma8ad:da6a178d2fb242cc462b7d0be8372627d1c197de" && docker exec -i -t datascience jupyter notebook --generate-config
#sudo docker exec -i -t datascience /bin/bash
	if [ ! -z "$3" ]; then
		SSH_KEY_STR=",ssh-keys=$2:ssh-rsa $3 $1"
	fi
   
    #SSH_KEY_STR=""
	#COMMAND=$(replace_with '"' '\"' "$COMMAND")
	#COMMAND=$(replace_with '&' '\&' "$COMMAND")
	#COMMAND=$(replace_with " " '\ ' "$COMMAND")
	#COMMAND=$(replace_with '|' '\|' "$COMMAND")

	information "Creating VM instance: $INSTANCE_NAME"
    cm="gcloud compute --project=$PROJECT instances create $INSTANCE_NAME --zone=us-east1-b --machine-type=n1-standard-1 --subnet=default --metadata=startup-script=\"$COMMAND$SSH_KEY_STR\" --maintenance-policy=MIGRATE --min-cpu-platform=Automatic --image=$DOCKER_IMAGE --image-project=$PROJECT --boot-disk-size=20GB --boot-disk-type=pd-standard --boot-disk-device-name=$INSTANCE_NAME --format=json 2>&1"
	#echo $cm
    
    cmd=$(gcloud compute --project=$PROJECT instances create $INSTANCE_NAME --zone=us-east1-b --machine-type=n1-standard-1 --subnet=default --metadata=startup-script="$COMMAND$SSH_KEY_STR" --maintenance-policy=MIGRATE --min-cpu-platform=Automatic --image=$DOCKER_IMAGE --image-project=$PROJECT --boot-disk-size=20GB --boot-disk-type=pd-standard --boot-disk-device-name=$INSTANCE_NAME --format=json 2>&1)
	#echo  "---$cmd---"

	index=$(strindex "$cmd" "Created")
	cmd=${cmd:$index+9}

	index=$(strindex "$cmd" "].")
	cmd=${cmd:$index+2}
	cmd=$(trim_this "$cmd")
	#echo "-$cmd-"

	if [[ $cmd == *"ERROR: "* ]]; then
		if [[ $cmd == *"$INSTANCE_NAME' already exists"* ]]; then
			error "VM Instance with name: \"$INSTANCE_NAME\" already exists"
		else
			error "Unable to create instance" "$cmd"
		fi
	elif [[ $cmd == *"networkInterfaces"* ]]; then
		ip=$(echo $cmd | jq --raw-output '.[0] | .networkInterfaces | .[0] | .accessConfigs | .[0] | .natIP')
		#echo "{\"user_name\":\"$2\",\"ip\":\"$ip\",\"instance\":\"$INSTANCE_NAME\"}"
        if [ ! -z "$COMMAND" ];then
		    wait_for_vm "http://$ip:8888/$INSTANCE_NAME"
        fi
		success "VM instance with name \"$INSTANCE_NAME\" has been created with ip: $ip"
		success "Web interface url: http://$ip:8888 with password: $PASSWORD"
		if [ -z "$3" ]; then
            success "SSH Public key authentication has been enabled for password less login from your IP"
			success "You can login to SSH with command: ssh $2@$ip"
		fi
	else
		error "Unable to create instance" "$cmd"
	fi

}
