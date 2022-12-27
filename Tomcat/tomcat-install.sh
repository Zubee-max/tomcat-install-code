#!/bin/bash
# TOMCAT.SH
# This script will install tomcat on Linux (Debian and RedHat based distributions)
# THIS SCRIPT IS WRITTEN AND MAINTAINED BY NEW ERA SOLUTIONS ACADEMY AND IS INTENDED FOR USE ONLY BY NEW ERA INSTRUCTORS AND HER STUDENTS

#DEFINE COLORS
Red='\033[1;31m'
Green='\033[1;32m'
NC='\033[0;m'

#ENFORCE ROOT USER
if [[ ! $(whoami) == root ]]
then
        echo -e "${Red}This script must be executed as root user"
        echo "Switch to root user or run this script with sudo"
        echo "Are you root?"
        sleep 1
        echo -e "Abruptly exiting... ${NC}" 
        exit 1
fi

# CHECK LINUX DISTRIBUTION
str=$(grep  "^ID=" /etc/os-release)
IFS='='
read -a strarr <<< "$str"
distro=$(echo ${strarr[@]} |awk '{print $NF}')

DEBIAN=("debian" "ubuntu")
RHEL=("rhel" "centos" "amzn")

# Check for value matching
if [[ " ${RHEL[@]} " =~ " ${distro} " ]]
then
        dist=rhel
elif [[ " ${DEBIAN[@]} " =~ " ${distro} " ]]
then
        dist=deb
else
        echo -e "${Red}Unable to reliably determine the distribution for this system."
        echo "Tomcat installation will therefore not proceed"
        echo -e "Exiting...${NC}"
        exit 1
fi


# INSTALL JAVA IF NOT PRESENT
if [[ ! -d /usr/lib/jvm ]]
then
        if [[ $(echo $dist) == deb ]]
        then
		apt update 
                apt install default-jdk -y
                apt install default-jre -y
		apt install openjdk-8-jre -y
        else
                yum install java-1.8.0-openjdk -y
        fi
fi

# Download necessary packages
if [[ ! -f /usr/bin/wget ]]
then
        sudo yum install wget -y
fi


# Download Tomcat package
if [[ -d /opt/tomcat ]];then
        echo -e "${Green}Tomcat Already Installed..\nProceeding to configure${NC}"
else
        mkdir /opt/tomcat
        wget -c https://downloads.apache.org/tomcat/tomcat-8/v8.5.84/bin/apache-tomcat-8.5.84.tar.gz
        tar xf apache-tomcat-8.5.84.tar.gz -C /opt/tomcat
        rm -rf apache-tomcat-8.5.84.tar.gz
        ln -s /opt/tomcat/apache-tomcat-8.5.84 /opt/tomcat/updated
        sh -c 'chmod +x /opt/tomcat/updated/bin/*.sh'
fi
        chown -R tomcat: /opt/tomcat/*
sleep 2

# Create Tomcat user
useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat

# Configure Tomcat
echo -e "[Unit]\nDescription=Apache Tomcat Web Application Container\nAfter=network.target\n\n[Service]\nType=forking\n\n" >/etc/systemd/system/tomcat.service
echo  "Please Input JAVA_HOME"
read JH
echo -e "Environment=JAVA_HOME=$JH\nEnvironment='CATALINA_PID=/opt/tomcat/updated/temp/tomcat.pid'\nEnvironment='CATALINA_HOME=/opt/tomcat/updated/'\nEnvironment='CATALINA_BASE=/opt/tomcat/updated/'\nEnvironment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'\nEnvironment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'\n\n" >>/etc/systemd/system/tomcat.service
echo -e "ExecStart=/opt/tomcat/updated/bin/startup.sh\nExecStop=/opt/tomcat/updated/bin/shutdown.sh\n\n" >>/etc/systemd/system/tomcat.service
echo -e "User=tomcat\nGroup=tomcat\nUMask=0007\nRestartSec=10\nRestart=always\n\n" >>/etc/systemd/system/tomcat.service
echo -e "[Install]\nWantedBy=multi-user.target" >> /etc/systemd/system/tomcat.service
sleep 2


# Reload the daemon and start service
systemctl daemon-reload
sleep 1
systemctl enable tomcat
systemctl start tomcat 
if [[ $(echo $?) != 0 ]];
then
        echo -e "${Red}Tomcat Installation Unsuccessful${NC}"
        exit 1
fi

# Set firewall rules
if [[ $(echo $dist) == deb ]];
then
        if [ -f /usr/bin/ufw ];then
                ufw allow 8080/tcp
        fi
else
        if [ -f /usr/bin/firewalld ];then
                firewall-cmd --zone=public --add-port=8080/tcp --permanent
        fi
fi
sleep 2

# Finish And Exit
echo -e "${Green}Tomcat Installation And Configuration Successfully Completed !!!${NC}"
exit $?
