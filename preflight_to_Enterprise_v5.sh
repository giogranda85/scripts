#!/bin/bash
clear
echo -e "\nSit back and take a break while we check your existing infrastructure\n"

#Need to determine what utils are on system?
#function verify_util {

#}

#========================
#Finding the hcl file
#========================


function find_vault_hcl() {

if [[ -f /etc/vault.d/vault.hcl ]] && [[ -f /etc/consul.d/consul.hcl ]] ;
then
        echo -e "Do you have Vault and Consul running on the same maching? This is not recommended on Vault 1.3 architecture\n\n Exiting"
        exit 0
elif [ -f /etc/vault.d/vault.hcl ];
then
        echo -e "Vault HCL detected\n"
        vaulthcl="/etc/vault.d/vault.hcl"
else
        echo -e "Your HCL files are not in the expected path; HCL files are expected in either /etc/vault.d/vault.hcl\nAdditional information can be referenced at:\nVault: https://learn.hashicorp.com/vault/operations/ops-deployment-guide#step-5-configure-vault\n"

fi

}

function find_consul_hcl() {

if [[ -f /etc/vault.d/vault.hcl ]] && [[ -f /etc/consul.d/consul.hcl ]] ;
then
        echo -e "Do you have Vault and Consul running on the same maching? This is not recommended on Vault 1.3 architecture\n\n Exiting"
        exit 0

elif [ -f /etc/consul.d/consul.hcl ];
then
        echo -e "Consul HCL detected\n"     
       consulhcl="/etc/consul.d/consul.hcl"
else
        echo -e "Your HCL files are not in the expected path; HCL files are expected in either /etc/consul.d/consul.hcl\nAdditional information can be referenced at:\nConsul: https://learn.hashicorp.com/consul/datacenter-deploy/deployment-guide#configure-consul-server- \n"

fi

}

#========================
#check the systemd configuration
#========================

function chk_vault_systemd () {

#Determine what systemd files are avaialble
if [[ -f /etc/systemd/system/vault.service ]] && [[ -f /etc/systemd/system/consul.service ]];
then
        echo -e "Do you have Vault and Consul running on the same maching? This is not recommended on Vault 1.3 architecture\n\n Exiting"
        exit 1

elif [ -f /etc/systemd/system/vault.service ];
then
        echo "Vault systemd detected"

#input the expected strings into tmp file to grep against
        echo -e "Description=\"HashiCorp Vault - A tool for managing secrets\"\nDocumentation=https://www.vaultproject.io/docs/\nRequires=network-online.target\n
After=network-online.target\nConditionFileNotEmpty=/etc/vault.d/vault.hcl\nStartLimitIntervalSec=60\nStartLimitBurst=3\nUser=vault\nGroup=vault\nProtectSystem=full\nProtectHome=read-only\nPrivateTmp=yes\nPrivateDevices=yes\nSecureBits=keep-caps\nAmbientCapabilities=CAP_IPC_LOCK\nCapabilities=CAP_IPC_LOCK+ep\nCapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK\nNoNewPrivileges=yes\nExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl\nExecReload=/bin/kill --signal HUP $MAINPID\nKillMode=process\nKillSignal=SIGINT\nRestart=on-failure\nRestartSec=5\nTimeoutStopSec=30\nStartLimitInterval=60\nStartLimitIntervalSec=60\nStartLimitBurst=3\nLimitNOFILE=65536\nLimitMEMLOCK=infinity\nWantedBy=multi-user.target">tmpfile

#reading tmp file and validating against systemd configuration
        echo "Checking /etc/systemd/system/vault.service"
        while read i;
        do
                grep "$i" /etc/systemd/system/vault.service 1>/dev/null
                #exit out is missing from systemd"
                if [ $? = 1 ]
                then
                        echo "Vault systemd is missing $i"
                        exit 0
                fi
        done < tmpfile
        echo "Systemd configuration validated"
        #Clean up the tmp file
        rm -fr tmpfile

else
        echo -e "Your systemd files are not in the expected path; systemd files are expected in either /etc/systemd/system/vault.service or /etc/systemd/system/vault.service\nAdditional information can be referenced at:\nVault: https://learn.hashicorp.com/vault/operations/ops-deployment-guide#step-3-configure-systemd\nConsul: https://learn.hashicorp.com/consul/datacenter-deploy/deployment-guide#configure-systemd "

fi

}

function chk_consul_systemd () {

#Determine what systemd files are avaialble
if [[ -f /etc/systemd/system/vault.service ]] && [[ -f /etc/systemd/system/consul.service ]];
then
        echo -e "Do you have Vault and Consul running on the same maching? This is not recommended on Vault 1.3 architecture\n\n Exiting"
        exit 1

elif [ -f /etc/systemd/system/consul.service ];
then

        echo "Consul systemd detected"

#input the expected strings into tmp file to grep against
        echo -e "Description=\"HashiCorp Consul - A service mesh solution\"
Documentation=https://www.consul.io/\nRequires=network-online.target\nAfter=network-online.target\nConditionFileNotEmpty=/etc/consul.d/consul.hcl\nType=notify\nUser=consul\nGroup=consul\nExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/\nExecReload=/usr/local/bin/consul reload\nKillMode=process\nRestart=on-failure\nLimitNOFILE=65536\nWantedBy=multi-user.target">tmpfile

#reading tmp file and validating against systemd configuration
echo "Checking /etc/systemd/system/consul.service"
        while read i;
        do
                grep "$i" /etc/systemd/system/consul.service 1>/dev/null
                #exit out is missing from systemd"
                if [ $? = 1 ]
                then
                        echo "Consul systemd is missing $i"
                        exit 0
                fi
        done < tmpfile
        echo "Systemd configuration validated"
        #Clean up the tmp file
        rm -fr tmpfile
else
        echo -e "Your systemd files are not in the expected path; systemd files are expected in either /etc/systemd/system/vault.service or /etc/systemd/system/vault.service\nAdditional information can be referenced at:\nVault: https://learn.hashicorp.com/vault/operations/ops-deployment-guide#step-3-configure-systemd\nConsul: https://learn.hashicorp.com/consul/datacenter-deploy/deployment-guide#configure-systemd "

fi
}

#========================
#checking for storage type and determine if suitable (Deny NFS)
#========================

#function check_storage () {
#determine if there are any NFS mounts

#echo "Checking for NFS mounts"

#mount |grep nfs 1>/dev/null

#if [ $? = 0 ]
#then
#        echo "NFS mount has been discovered and should NOT be used as the supporting storage device. Determining if used by Hashicorp"

#add logic to check what vault / consul is using

#fi

#}

#========================
#Checking Amount of Memory, CPU count, and Disk throughput
#========================

function chk_vault_hardware () {

#NEED TO PLAY WITH FLOATING DECIMALS (PRINTF) 

#check amount of memory, proc meminfo should always be in terms of KB
memtotal=`cat /proc/meminfo|grep MemTotal|awk '{print $2}'`
memfree=`cat /proc/meminfo|grep MemFree|awk '{print $2}'`
percentfree=`awk 'BEGIN{printf("%0.2f", ('$memfree' / '$memtotal') * 100)}'`

echo -e "Total memory: $memtotal KB\nPrecent free: $percentfree%\n"

#vault and consule Memory requirements
#4 - 8 GB RAM - small - vault
#16 - 32 GB RAM - large - vault

#Checking memory for Vault/Consul configuration

if [[ memtotal < 4194304 ]] && [[ -f /etc/vault.d/vault.hcl ]]
then
	echo "The amount of memory will not support Vault enterprise, please increase to at least 4GB"
	exit 0

elif [[ memtotal > 4194304 ]] && [[ memtotal < 8388608 ]] && [[ -f /etc/vault.d/vault.hcl ]]
then
        echo "The amount of memory will support a small Vault enterprise configuration"

elif [[ memtotal > 8388608 ]] && [[ -f /etc/vault.d/vault.hcl ]]
then
        echo "The amount of memory will support a large Vault enterprise configuration" 
fi

#verify the number of cores and cpu type

cpucount=`cat /proc/cpuinfo|grep processor|wc -l`

#vault ane consul CPU requirements are the same
#2 CPU core - small
#4-8 CPU code - large

#Check the number of cores detected by kernel
if [ $cpucount = 1 ];
then
echo "Only a single core has been detected, the number of cores is insufficient to run enterprise"
exit 0

elif [[ $cpucount > 1 ]] && [[ $cpucount < 4 ]];
then
echo "Number of cores support a small platform"

elif [ $cpucount > 4 ];
then
echo "Number of cores support a large platform"
fi

#Checking vault and consul Disk requirements
        #25 GB - small - vault
        #50 GB - large - vault
        #50 GB - small - consul
        #100 GB - large - consul

#Check Storage Stanza in Vault to verify what backend is being used

grep "storage \"consul" /etc/vault.d/vault.hcl 1> /dev/null

if [ $? = 0 ]
then
        echo "Please run this script on each Consul node to validate storage in use"

#NEED TO CHECK WITH IF THERE IS ANOTHER WAY TO GRACEFULLY WRITE TO PATH THAT IS OWNED BY CONSUL; SU TO CONSUL USER WILL RESULT IN PASSWORD BEING PROMPTED
#FOR NOW, SUDO IS USED FOR DD COMMAND

#Checking disk size, disk type, and throughput

elif [ -f /etc/consul.d/consul.hcl ]
then
	#checking throughput
	mountpoint=`grep data_dir /etc/consul.d/consul.hcl|cut -d\" -f2`
	echo -e "\n\nTesting sequential write throughput on mount point: $mountpoint \n\nThroughput:\n"
	
	sudo dd if=/dev/zero of=$mountpoint/testing bs=512k count=2048|tail -1

	echo -e "\n\nTesting sequential read throughput on mount point: $mountpoint \n\nThroughput:\n"
	sudo dd if=$mountpoint/testing of=$mountpoint/readback bs=512k count=2048|tail -1
	#cleanup
	sudo rm -fr $mountpoint/testing $mountpoint/readback

	#checking disk size
	mount |grep $mountpoint 1> /dev/null
	
	if [ $? != 0 ]
	then
		echo -e "Consul mount point is not on a dedicated partition\nConsul mount point: $mountpoint \n`mount`"
	else
		echo "Consul mount point disk space:"
		df $mountpoint	
		tmp=`df -g $mountpoint|tail -1|awk '{print $2}'`
		if [ $tmp < 50 ] 
		then
			echo "The minimum size for Consul mount point needs to be at least 50GB"
		elif [[ $tmp > 50 ]] && [[ $tmp < 100 ]]
		then
			echo "Consul mount point is $tmp GB and can support a small environment"
		elif [ $tmp > 100 ]
		then
			echo "Consul mount point is $tmp GB and can support a large environment"	
		fi
	fi

	#verifying disk is not an NFS volume
	mount |grep -E '$mountpoint.*nfs'
	if [$? = 0 ]
	then
		echo "Using an NFS volume as a mount point for Consul is not supported"	
	fi
else

	echo "No configuration file found to evaluate mount point"

fi

}

function chk_consul_hardware () {

#NEED TO PLAY WITH FLOATING DECIMALS (PRINTF) 

#check amount of memory, proc meminfo should always be in terms of KB
        memtotal=`cat /proc/meminfo|grep MemTotal|awk '{print $2}'`
        memfree=`cat /proc/meminfo|grep MemFree|awk '{print $2}'`
	percentfree=`awk 'BEGIN{printf("%0.2f", ('$memfree' / '$memtotal') * 100)}'`
	echo -e "Total memory: $memtotal KB\nPrecent free: $percentfree%\n"


        #Consule Memory requirements
        #8 - 16 GB RAM - small - consul
        #32 - 64 GB RAM - large - consul 

#Checking memory for Consul configuration

if [[ memtotal < 8388608 ]] && [[ -f /etc/consul.d/consul.hcl ]]
then
        echo "The amount of memory will not support Consul enterprise configuration, please increase to at least 8GB"
        exit 0

elif [[ memtotal > 8388608 ]] && [[ memtotal < 16777216 ]] && [[ -f /etc/consul.d/consul.hcl ]]
then
        echo "The amount of memory will support a small Consul enterprise configuration"

elif [[ memtotal > 16777216 ]] && [[ -f /etc/consul.d/consul.hcl ]]
then
        echo "The amount of memory will support a large Consul enterprise configuration"
fi

#verify the number of cores and cpu type

        cpucount=`cat /proc/cpuinfo|grep processor|wc -l`

        #vault ane consul CPU requirements are the same
        #2 CPU core - small
        #4-8 CPU code - large

        #Check the number of cores detected by kernel
        if [ $cpucount = 1 ];
        then
                echo "Only a single core has been detected, the number of cores is insufficient to run enterprise"
               # exit 0

        elif [[ $cpucount > 1 ]] && [[ $cpucount < 4 ]];
        then
                echo "Number of cores support a small platform"

        elif [ $cpucount > 4 ];
        then
                echo "Number of cores support a large platform"
        fi

#Checking Consul Disk requirements
        #50 GB - small - consul
        #100 GB - large - consul

#Check Storage Stanza in Vault to verify what backend is being used

grep "storage \"consul" /etc/vault.d/vault.hcl 1> /dev/null

if [ $? = 0 ]
then
        echo "Please run this script on each Consul node to validate storage in use"

#NEED TO CHECK WITH IF THERE IS ANOTHER WAY TO GRACEFULLY WRITE TO PATH THAT IS OWNED BY CONSUL; SU TO CONSUL USER WILL RESULT IN PASSWORD BEING PROMPTED
#FOR NOW, SUDO IS USED FOR DD COMMAND

#Checking disk throughput

elif [ -f /etc/consul.d/consul.hcl ]
then
	mountpoint=`grep data_dir /etc/consul.d/consul.hcl|cut -d\" -f2`
	echo -e "\n\nTesting sequential write throughput on mount point: $mountpoint \n\nThroughput:\n"
	
	sudo dd if=/dev/zero of=$mountpoint/testing bs=512k count=2048|tail -1

	echo -e "\n\nTesting sequential read throughput on mount point: $mountpoint \n\nThroughput:\n"
	sudo dd if=$mountpoint/testing of=$mountpoint/readback bs=512k count=2048|tail -1
	#cleanup
	sudo rm -fr $mountpoint/testing $mountpoint/readback	

	#checking disk size
	mount |grep $mountpoint 1> /dev/null
	
	if [ $? != 0 ]
	then
		echo -e "Consul mount point is not on a dedicated partition\nConsul mount point: $mountpoint \n`mount`"
	else
		echo "Consul mount point disk space:"
		df $mountpoint	
		tmp=`df -g $mountpoint|tail -1|awk '{print $2}'`
		if [ $tmp < 50 ] 
		then
			echo "The minimum size for Consul mount point needs to be at least 50GB"
		elif [[ $tmp > 50 ]] && [[ $tmp < 100 ]]
		then
			echo "Consul mount point is $tmp GB and can support a small environment"
		elif [ $tmp > 100 ]
		then
			echo "Consul mount point is $tmp GB and can support a large environment"	
		fi
	fi
        #verifying disk is not an NFS volume
        mount |grep $mountpoint|grep nfs
        if [ $? = 0 ]
        then
                echo "Using an NFS volume as a mount point for Consul is not supported" 
        fi
else

	echo "No configuration file found to evaluate mount point"

fi

}


#========================
#Checking ulimts, disk timeout, 
#========================

function kernelsettings () {

	#NEED TO ADD FUNCTION TO CHECK FOR DEBIAN VS LINUX

	echo -e "\nFile descriptor limits:\nHard limit is: `ulimit -Hn`\nSoft limit is: `ulimit -Sn`\n\n"

	#Generic timeouts will be in:
	echo -e "\nChecking timeout on all sg devices:" 

	for i in `ls -1 /sys/class/scsi_generic/*/device/timeout`
	do 
		echo "The timeout for $i is: "
		cat $i
	done 
	#Mapping the sg devices to an SDA device would require sg3_utils to be installed

}



# check ulimit
# disk timeout between different flavors
# disabling cache test
# validate syntax in hcl


#========================
#TO DO's
#========================

#check server hardening. 

#maybe latency to the other consul server nodes
#Breakdown functions and add the menu

#pre-flight and post-takeoff
#post-takeoff would list consul members and then check network connectivity to them
#(reachable, latency, dropped packets, etc)


#========================
#Menu to prompt user
#========================


echo -e "\nWhat type of node is being evaluated?\n\n1) Vault\n2) Consul\n"
#3) Terraform"

read -p "Please choose: " INPUT
if [ "$INPUT" -eq 1 ];
        then
		clear
		find_vault_hcl
		chk_vault_systemd
		chk_vault_hardware	
	
        elif [ "$INPUT" -eq 2 ];
        then
                clear
		find_consul_hcl 
		chk_consul_systemd
		chk_consul_hardware
fi               


#========================
#Calling function manually
#========================

#find_hcl
#chk_systemd
#chk_hardware
#kernelsettings

