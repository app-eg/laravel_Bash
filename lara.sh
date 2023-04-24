#!/bin/bash
#clear screen
clear

#set -e

#typeset
declare -A config

function loadConfig(){
if [ -e "config.conf" ]; then 
 source config.conf
else
checkError "configuration file not found"
fi


} 

function clearCach(){

php artisan --version >/dev/null 2>&1
checkError "Check PHP Artisan"

php artisan view:clear  >/dev/null 2>&1
checkError
sleep .25
echo -e "- clear View \t\t \e[1;42m OK \e[0m"

php artisan cache:clear >/dev/null 2>&1
checkError
sleep .25
echo -e "- clear cache \t\t \e[1;42m OK \e[0m"


php artisan route:clear >/dev/null 2>&1
checkError
sleep .25
echo -e "- clear route \t\t \e[1;42m OK \e[0m"

php artisan clear-compiled >/dev/null 2>&1
checkError
sleep .25
echo -e "- clear compiled \t \e[1;42m OK \e[0m"

echo "" > storage/logs/laravel.log >/dev/null 2>&1
checkError
sleep .25
echo -e "- clear log  \t\t \e[1;42m OK \e[0m"

   
}

function setupMail()
{
    
if [[ ! $(which maildev) ]]; then

npm i maildev -g
maildev
  else 
maildev
  fi  
checkError
 
}


function grantPermission(){
   

sudo chmod -R ug+rwx  bootstrap/cache >/dev/null 2>&1
checkError
sleep .25
echo -e "- bootstrap/cache \t\t \e[1;42m OK \e[0m"

sudo chmod -R ug+rwx  storage >/dev/null 2>&1
checkError
sleep .25
echo -e "- storage \t\t\t \e[1;42m OK \e[0m"




}

function phpTest(){
./vendor/bin/phpunit
checkError
sleep .25
echo -e "- Unit Test \t\t \e[1;42m OK \e[0m"

}


function storageLink(){
php artisan storage:link >/dev/null 2>&1
checkError "Execute command in laravel "
sleep .25
echo -e "- Create the symbolic link\t\t \e[1;42m OK \e[0m"

}


function compressTask(){
fileName=$(date +"%S_%H_%M-%m_%d_%Y").tar.gz     
tar -cvzf  ${fileName} --exclude='*.tar.gz'   *  >/dev/null 2>&1
checkError
sleep .25
echo -e "- Compress Path : \e[0;33m ${fileName}\e[0m\t\t \e[1;42m OK \e[0m"    
}


function BackupMysql(){

#check mysql connection

if [[ ! $(which mysql)  ]]; then
 checkError "Mysql not Install"
fi



#prompt hostname user pass databaseName 
read -p  "Enter hostName userName databaseName use comma(,) ? " db
IFS=,
read -r hostName userName  databaseName <<< $db
# -n for empty
[ ! -z "$hostName" ] || checkError "Invalid hostName"
[ ! -z "$userName" ] || checkError "Invalid userName"
[ ! -z "$databaseName" ] || checkError "Invalid databaseName"
#echo $hostName $user $pass $databaseName 
#create Backup and provide path
fileName=${databaseName}-$(date +"%S_%H_%M-%m_%d_%Y").sql
mysqldump -h ${hostName} -u ${userName} -p   ${databaseName} > ${fileName}

#privide path file
checkError
sleep .25
echo -e "- BackUp File  : \e[0;33m ${fileName}\e[0m\t\t \e[1;42m OK \e[0m"  

#end

}



function shareFiles(){
printf "\e[0;33m Enter the full file path:\e[0m  :  \n"

read fileName

echo -e $fileName

if [ -f $fileName ]
then

curl -H "Max-Days: 30" --progress-bar -v --upload-file {$fileName} https://transfer.sh/
checkError
echo -e "- Upload File\t\t \e[1;42m OK \e[0m"

else
checkError "Path not File"
fi

}


function generateSSL(){

read -p  "Enter Domain Name ex (localhost , appsite.test):  ? " domain

[ ! -z "$domain" ] || checkError "Invalid domain"

#check openssl
if [[ ! $(which openssl) ]]; then
 checkError "openssl not Install,apt-get install openssl -y"
fi

 

cat > $domain.csr.cnf <<EOL
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn] 
C=EG 
ST=Egypt 
L=Egypt 
O=Global Security 
OU=IT Department 
emailAddress=app_eg@mail.com 
CN = ${domain} 
EOL
 


cat > $domain.ext <<EOL
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${domain}
EOL


#domain



#Generating RSA private key
openssl genrsa -out $domain"_"rootCA.key 2048
 
openssl req -x509 -new -nodes -key $domain"_"rootCA.key -sha256 -days 3650 -out $domain.pem -subj "/C=EG/ST=Egypt/L=Egypt/O=Global Security/OU=IT Department/CN=$domain"
 
#create key
openssl req -new -sha256 -nodes -out $domain.csr -newkey rsa:2048 -keyout $domain.key -config <( cat $domain.csr.cnf )
 
openssl x509 -req -in $domain.csr -CA $domain.pem -CAkey $domain"_"rootCA.key -CAcreateserial -out $domain.crt -days 3650 -sha256 -extfile $domain.ext
checkError

#clear
rm -f $domain"_"rootCA.key 
rm -f $domain.csr.cnf 
rm -f $domain.csr
rm -f $domain.ext
rm -f $domain.srl
checkError
echo -e "- \e[0;33m Update Nginx or Apache Virtual Host \e[0m\t\t"  
echo -e "- Apache: SSLCertificateFile  \e[0;33m ${domain}.crt\e[0m\t\t"   
echo -e "- Apache: SSLCertificateKeyFile \e[0;33m ${domain}.key\e[0m\t\t"

echo -e "- Nginx: ssl_certificate  \e[0;33m ${domain}.crt\e[0m\t\t"   
echo -e "- Nginx: ssl_certificate_key \e[0;33m ${domain}.key\e[0m\t\t"

echo -e "- Chromium -> Setting -> (Advanced) Manage Certificates -> Import ->  : \e[0;33m $domain.pem\e[0m\t\t" 


}


function startServe(){
  read -p  "Enter Port  ? " port
  read -p  "Enter Directory you want to serve Default (.) - public for laravel ? " public

[ ! -z "$port" ] || checkError "Invalid Port"

[ ! -z "$public" ] || public="."
 php -S localhost:${port} -t $public

 

}



function updateSys()
{
sudo rm /var/lib/dpkg/lock
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
#sudo dpkg --configure -a
sudo apt-get update 
}




function installLatavel(){

read -p  "Enter Version Number [6,7,8,9,10]  :  ? " ver


#choose version

[ ! -z "$ver" ] || checkError "Invalid Laravel Version"

if [[ ! $(which composer)  ]]; then

updateSys
sudo apt install php-cli unzip
sudo apt install php-mbstring
sudo apt install curl unzip
sudo apt install php php-curl
curl -sS https://getcomposer.org/installer -o composer-setup.php
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
checkError "composer "
fi

 

#install laravel

# if ! [[ $ver =~ '^[0-9]+$' ]]; 
#    then echo "error: Not a number" >&2; exit 1 
# fi
 
workingLaravel="laravel-app"  #deefault laravel-app   use . for same place

if [ $ver -ge 6 ] && [ $ver -le 10 ]
then
 
if [ $ver -ge 7 ]
then 
  composer create-project laravel/laravel:^{$ver} ${workingLaravel}
else
 composer create-project --prefer-dist laravel/laravel ${workingLaravel} "6.*"
fi



else
checkError "Error Laravel Version ${var} "

fi







}




function destroyPort(){

read -p  "Enter Port you want to kill:  ? " port

[ ! -z "$port" ] || checkError "Invalid Port"

kill -9 $(lsof -t -i :${port}) 2>/dev/null

if [ $? -eq 0 ]
then
printf "Kill PORT :\e[0;41m %5.5s  ${port}  \e[0m\n"
else 
 
echo -e "================\e[1;33m NO PORT OPEN \e[0m================"
 
fi

}


function execCommand(){
loadConfig
padding="......................................"
cnt=0
for str in "${cmd[@]}"
do
  eval "$str"  2>/dev/null  #error stderr
 
checkError "CMD -> ${str}"
sleep .25
# echo -e "- Command [\e[0;33m $str \e[0m] \t \e[0;32m OK \e[0m"
# printf   "\055> \e[0;35m Command\e[0m [ \e[0;33m $str\e[0m ] %s%s\n  $padding [\e[0;32mOK\e[0m]   "  
# printf   "\055> \e[0;35m Command\e[0m [\e[0;33m$str\e[0m]\t\t${padding}[\e[0;32mOK\e[0m] \n"  

#printf "\055>\e[0;35mCommand\e[0m%b%.20s%b\n" "[\e[0;33m $str \e[0m]" "$padding" "[\e[0;32mOK\e[0m]"

   printf "\055> \e[0;35m Command\e[0m %.20s Result %b\n" \
        "$str ...................." "[\e[0;32mOK\e[0m]"

done


}

function clear(){
    printf "\033c"
}



function checkError(){

exitstatus=$?
message=$1 || "-"
if [ ! $exitstatus  -eq 0 ]; then
 echo -e "\n\e[0;41mFail to complete a task [${message}]  \e[0m\n"
 exit 1
fi

}

function message(){

exitstatus=$?
message=$1
if [ $exitstatus  -eq 0 ]; then
echo -e "\n\e[1;42m ${message} done   \e[0m\n"
else
 echo -e "\n\e[0;41mFail to complete a task  \e[0m\n"
 exit 1
fi

}







while [ 1 ]
do
echo -e "+ \e[0;44m Choose from the List  \e[0m\t\t "  
echo ""  
#Menu Select
options=("Install Laravel" "Start Server"  "Clear Cache" "Permission Storage,Cache" "Unit Test" "Symbolic link" "Compress Project" "MailDev(Testing)" "Custom Commands"
"Share Files" "BackUp Database Mysql" "Create SSL" "Kill Port" "Show Menu" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Clear Cache")
            echo -e "\e[0;32m -> Clear Cache...\e[0m"
           clearCach
           message "Clear Cache"
            ;;
        "Permission Storage,Cache")
          echo -e "\e[0;32m -> Permission Storage,Cache...\e[0m"
         grantPermission
         message "Permission Granted"
            ;;
        "Unit Test")
           echo -e "\e[0;32m -> Unit Test...\e[0m"
           phpTest
           message "PHP Unit Test"
            ;;
        "Symbolic link")
           echo -e "\e[0;32m -> Symbolic link...\e[0m"
           storageLink
           message "Symbolic link"
           ;;

        "Compress Project")
           echo -e "\e[0;32m -> Compress Project...\e[0m"
           compressTask  
           message "Compress Project"
           ;;

       "Custom Commands")
           echo -e "\e[0;32m -> Execute Custom Commands...\e[0m"
           execCommand
           message "Custom Commands"
          ;;

        "Share Files")
          echo -e "\e[0;32m -> Share Files using transfer.sh...\e[0m"
          shareFiles
          message "Share Files"
       ;;
      "BackUp Database Mysql")
        echo -e "\e[0;32m -> BackUp Database Mysql...\e[0m"
         BackupMysql
         message "BackUp Database Mysql"
       ;;
      "Create SSL")
        echo -e "\e[0;32m -> Create SSL For Local Development...\e[0m"
        generateSSL
        message "SSL Create"
       ;;
      "Kill Port")
        echo -e "\e[0;32m -> Kill Port...\e[0m"
        destroyPort
      
       ;;
       "Start Server")
        echo -e "\e[0;32m -> Run PHP Server...\e[0m"
        startServe
     
       ;;
       "MailDev(Testing)")
            echo -e "\e[0;32m -> MailDev Testing...\e[0m"
           setupMail
           message "MailDev Install "
            ;;

    "Install Laravel")
        echo -e "\e[0;32m -> Install Laravel...\e[0m"
        installLatavel
        message "Laravel install"
       ;;

      "Show Menu")
            break
            ;;

        "Quit")
            exit 1
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
done
#-------------------------------------------------------------------

