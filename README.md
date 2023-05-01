***This script was Authored by Jake Bloom OCI Principal Network Solution Architect. This is not an Oracle supported script. No liability from this script will be assumed and support is best effort.***

# Goal
Automate bastion sessions using OCI CLI and shell scripting.

# Requirements
OCI CLI needs to be installed on the client machine before this script can be used.

https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm
# Usage

**Set your cryptography files and your Bastion Host OCID in the variables of the script.** 

private_key_file=~/.ssh/id_rsa #Add Your Private Key File

public_key=$(cat ~/.ssh/id_rsa.pub) #Add your matching Public Key File

bastion_ocid="ocid1.bastion.oc1.iad.xxx" #Add your Bastion OCID

**Run the script**
./bastion_session_automator.sh

Add a SOCKS5 proxy to your web browser on the localhost:localport number and traffic will forward to OCI.

**Optional**

For non-SOCKS5 traffic, uncomment and modify the optional_port_forwarding variable and traffic will forward to that specific host. 
