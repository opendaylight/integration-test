#install java 8 for ubuntu
echo "installing java..."
sudo apt-get install -y -q software-properties-common debconf-utils > null
sudo add-apt-repository -y ppa:webupd8team/java > null
sudo apt-get update > /tmp/java-install.log
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 seen true" | sudo debconf-set-selections
sudo apt-get install -y -q oracle-java8-installer > null
sudo apt-get install -y -q oracle-java8-set-default > null
java -version
