#!/bin/bash


filename=$1

if [ -z "$filename" ]; then
	echo "Introduceti un nume de fisier"
	exit 1;
fi

if [ ! -f "$filename" ]; then
	 echo "$filename nu exista"
	exit 1;
fi

echo "===RAPORT SECURITATE FTP: $fileame==="

perm=$(stat -c %a "$filename")
echo "Permisiuni detectate: $perm"

if [ "$perm" != "600" ] && [ "$perm" != "644" ]; then
	echo "!ATENTIE: Permisiuni nesigure. Recomandat: 600."
fi

echo "--------------------------------"

verifica_setare() {
setare=$1
valoare_buna=$2
mesaj_eroare=$3

actual=$(grep "^$setare=" "$filename" | tail -1 |cut -d'=' -f2)

if [ -z "$actual" ]; then
	echo "INFO: $setare: Nu este configurat (se foloseste setarea standard)."
elif [ "$actual" == "$valoare_buna" ]; then
	echo "OK. $setare este $actual."
else
	echo "!!ALERTA: $setare este $actual! $mesaj_eroare"
fi
}

verifica_setare "anonymous_enable" "NO" "Oricine se poate loga fără parolă!"
verifica_setare "chroot_local_user" "YES" "Utilizatorii pot vedea fișierele de sistem!"
verifica_setare "ssl_enable" "YES" "Parolele sunt trimise necriptat prin rețea!"

echo "---------------------------------------"

echo "Analiză duplicate:"
duplicate=$(grep -v "^#" "$filename" | cut -d'=' -f1 | sort | uniq -d)

if [ -z "$duplicate" ]; then
    echo "Nu s-au găsit setări duplicate."
else
    for d in $duplicate; do
        echo "! Setarea '$d' apare de mai multe ori. Serverul o va folosi pe ultima."
    done
fi

echo "=== SFÂRȘIT RAPORT ==="
