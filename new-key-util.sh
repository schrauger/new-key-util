#!/bin/bash
source settings.cfg
if [ -z $2 ]
then
	domain=$default_domain
else
	domain=$2
fi
if [ -z $3 ]
then
	tld=$default_tld
else
	tld=$3
fi

subdomain=$1
if [ -z $subdomain ]

then
	echo "Usage: new_key_util.sh NEW_SUBDOMAIN {domain=cooldomain} {tld=com}"
	exit 1

fi

csr="$subdomain"_"$domain"_"$tld".csr
key="$subdomain"_"$domain"_"$tld".key
crt="$subdomain"_"$domain"_"$tld".crt
crt_chain="$subdomain"_"$domain"_"$tld".chained.crt

if [ -e "$key_location"/"$key" ]
then
	echo "Domain key already exists. Backing up key and any certs."
	mv $key_location/$key $bak_location/$key$(date +"%Y%m%d%H%M")
	mv $crt_location/$crt $bak_location/$crt$(date +"%Y%m%d%H%M")
	mv $crt_location/$crt_chain $bak_location/$crt_chain$(date +"%Y%m%d%H%M")
elif [ -e "$csr_location"/"$crt" ]
then
	echo "Cert already exists, but no key found. Backup up cert."
	mv $crt_location/$crt $bak_location/$crt$(date +"%Y%m%d%H%M")
	mv $csr_location/$csr $bak_location/$csr$(date +"%Y%m%d%H%M")
elif [ -e "$csr_location"/"$csr" ]
then
	echo "CSR already exists, but no key or cert found. Backing up CSR."
	mv $csr_location/$csr $bak_location/$csr$(date +"%Y%m%d%H%M")
fi
openssl req -nodes -newkey rsa:2048 -keyout $key -out $csr
nano $csr
sudo mv -n $key $key_location/$key
sudo nano $crt_location/$crt
sudo cat $crt_location/$crt $crt_location/sub.class1.server.ca.pem $crt_location/ca-bundle.pem >> $crt_location/$crt_chain
echo "Your private key is available at: $key_location/$key"
echo "Your public key (individual) is available at: $crt_location/$crt"
echo "Your public key (chained) is available at: $crt_location/$crt_chained"
# create a new dns record for this domain.
# for now, just drop any response and assume it worked.
curl https://www.cloudflare.com/api_json.html \
 -d 'a=rec_new' \
 -d "tkn=$cloudflare_token" \
 -d "email=$cloudflare_email" \
 -d "z=$domain.$tld" \
 -d 'type=CNAME' \
 -d "name=$subdomain" \
 -d "content=$domain.$tld" \
 -d 'ttl=1' > /dev/null 2>&1
echo "Your new domain, $subdomain.$domain.$tld, has been registered in CloudFlare, your DNS provider."
