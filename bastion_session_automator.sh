private_key_file=~/.ssh/id_rsa
public_key=$(cat ~/.ssh/id_rsa.pub)
bastion_ocid="ocid1.bastion.oc1.iad.amaaaaaac3adhhqa4bjhudnoywk2t4rzncgty72hwibdbotyuy4xaxtpsh5a"
session_ttl=3600

#optional_port_forwarding=RANDOM_LOCAL_PORT:OCI_PRIVATE_IP:OCI_PORT_NUMBER
#EXAMPLE: optional_port_forwarding=7777:10.0.0.41:22
optional_port_forwarding=7777:10.0.0.41:22


####RUN THE SCRIPT#####
#Get Local Port Variable
port_forwarding_local_port=$(echo $optional_port_forwarding | awk -F ':' '{print $1}')

#Make Sure there isn't already a session running.
existing_socks5=$(netstat -ant | awk '{print $4}' | grep 25000)
if [ ! -z "$existing_socks5" ]; then
    echo ""
    echo "There is an existing SOCKS5 session running on port 25000."
    echo "Exiting this script without creating a new session."
    exit 0
fi

if [ ! -z "$port_forwarding_local_port" ]; then
    existing_port_forwarding=$(netstat -ant | awk '{print $4}' | grep "$port_forwarding_local_port")
    if [ ! -z "$existing_port_forwarding" ]; then
        echo ""
        echo "There is an existing port forwarding connection on $port_forwarding_local_port"
        echo "Exiting this script without creating a new session."
        exit 0
    fi
fi

#Create a new Bastion Session
bastion_session=$(oci bastion session create-session-create-dynamic-port-forwarding-session-target-resource-details \
--bastion-id $bastion_ocid \
--key-details "{\"publicKeyContent\": \"$public_key\"}" \
--wait-for-state "SUCCEEDED" \
--session-ttl-in-seconds $session_ttl)

bastion_session_identifier=$(echo $bastion_session | jq | grep "identifier" | awk -F ':' '{print $2}' | tr -d "' \"")
echo "Bastion Session Identifier, $bastion_session_identifier"
echo "Script will sleep for 10 seconds to give the Bastion Session time to create."

#There is healthchecks here that can be used, making this better. I recommend using the Python script for more advanced features.
#This value might need to be tuned
sleep 10

#Get the metadata from the new bastion session
bastion_session_details=$(oci bastion session get --session-id $bastion_session_identifier)

#Get the SSH details from the new bastion session
bastion_session_ssh_details=$(echo $bastion_session_details | jq | grep command | cut -d ' ' -f16 | tr -d "' \"")

if [ -z "$optional_port_forwarding" ]; then
    echo ""
    echo "OCI SOCKS5 PROXY @ localhost:25000"
    ssh -i $private_key_file -N -D 127.0.0.1:25000 -p 22 "$bastion_session_ssh_details" \
    -o PubkeyAcceptedKeyTypes=ssh-rsa -o HostKeyAlgorithms=ssh-rsa -o serveraliveinterval=60 &
fi

if [ ! -z "$optional_port_forwarding" ]; then
    echo ""
    echo "OCI SOCKS5 PROXY @ localhost:25000"
    echo "Port Forwarding @ localhost:$port_forwarding_local_port"
    ssh -i $private_key_file -N -D 127.0.0.1:25000 -p 22 "$bastion_session_ssh_details" \
    -o PubkeyAcceptedKeyTypes=ssh-rsa -o HostKeyAlgorithms=ssh-rsa -o serveraliveinterval=60 -o StrictHostKeyChecking=no & 
    ssh -i $private_key_file -N -L $optional_port_forwarding $bastion_session_ssh_details \
    -o PubkeyAcceptedKeyTypes=ssh-rsa -o HostKeyAlgorithms=ssh-rsa -o serveraliveinterval=60 -o StrictHostKeyChecking=no &
fi
