#!/bin/bash


filename=$1

if [ -z "$filename" ]; then
	echo "Eroare: Trebuie sa specificati calea catre fisierul de configurare."
   	echo "Utilizare: $0 /etc/vsftpd.conf"
	exit 1;
fi

if [ ! -f "$filename" ]; then
	echo "Eroare: Fisierul '$filename' nu a fost gasit!"
	exit 1;
fi

echo "===RAPORT SECURITATE FTP: $filename==="

#se citesc permisiunile si proprietarul fisierului de configurare
perm=$(stat -c %a "$filename")
owner=$(stat -c %U "$filename")

echo "Permisiuni: $perm | Proprietar: $owner "

if [ "$perm" != "600" ] && [ "$perm" != "644" ]; then
    echo "!! ALERTA: Permisiuni nesigure! Recomandat 600."
fi
if [ "$owner" != "root" ]; then
    echo "!! ALERTA: Fisierul nu este detinut de root! Risc de manipulare a fisierului."
fi

echo "--------------------------------"

echo -e "\n==== ANALIZA OPTIUNI CRITICE ==== "

#functia generala pentru verificarea unei directive de configurare
verifica_setare() {
setare=$1
valoare_buna=$2
mesaj_eroare=$3

#luam ultima aparitie a directivei (daca sunt duplicate, ultima ramane activa, chiar daca exista spatii in plus)
actual=$(grep -v '^[[:space:]]*#' "$filename" \
	| grep -E "^[[:space:]]*$setare[[:space:]]*=" \
	| tail -1 \
	| sed 's/#.*$//' \
	| cut -d'=' -f2 \
	| tr -d '[:space:]')

if [ -z "$actual" ]; then
	echo "INFO: $setare nu este configurat (se foloseste valoarea implicita)."
elif [ "$actual" == "$valoare_buna" ]; then
	echo "OK: $setare este $actual (valoare recomandata)."
else
	echo "!! ALERTA: $setare este $actual! $mesaj_eroare"
fi
}

verifica_setare "anonymous_enable" "NO" "Acces anonim activ, oricine se poate loga fara parola!"
verifica_setare "chroot_local_user" "YES" "Utilizatorii locali nu sunt izolati (pot vedea mai multe fisiere din sistem)!"
verifica_setare "ssl_enable" "YES" "Conexiunile nu sunt criptate (parolele pot fi interceptate)!"
verifica_setare "local_enable" "YES" "Utilizatorii locali nu se pot autentifica."
verifica_setare "write_enable" "YES" "Serverul este Read-Only (utilizatorii nu pot scrie pe server)."
verifica_setare "allow_writeable_chroot" "NO" "Risc securitate: scriere permisa in directorul chroot."
verifica_setare "max_clients" "50" "Fara limita de clienti (Risc de atac DoS)."
verifica_setare "max_per_ip" "5" "Un singur IP poate ocupa prea multe conexiuni in acelasi timp."
echo "---------------------------------------"

echo "Analiza directive duplicate:"
#cautam directive care apar de mai multe ori in fisier (ignoram comentariile)
duplicate=$(grep -v '^[[:space:]]*#' "$filename" \
	 | awk -F= '/=/{ key=$1; gsub(/^[ \t]+|[ \t]+$/,"",key); print key }' \
	 | sort | uniq -d)

if [ -z "$duplicate" ]; then
    echo "OK: Nu s-au gasit setari duplicate."
else
	for d in $duplicate; do
        	linii=$(grep -n -E "^[[:space:]]*$d[[:space:]]*=" "$filename" \
	 		| cut -d':' -f1 | tr '\n' ',' | sed 's/,$//')
        	val_finala=$(grep -E "^[[:space:]]*$d[[:space:]]*=" "$filename" \
			 | tail -1 \
			 | sed 's/#.*$//' \
			 | cut -d'=' -f2- \
			 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        	echo "!! Directiva '$d' apare in mod repetat la liniile ($linii). Valoarea finala folosita: $val_finala."
    	done
fi
echo "---------------------------------------"
echo "SFARSIT RAPORT"
echo "---------------------------------------"
