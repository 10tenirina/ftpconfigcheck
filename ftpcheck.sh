#!/bin/bash


filename=$1

if [ -z "$filename" ]; then
	echo "EROARE: Trebuie să specificati calea către fisierul de configurare."
   	echo "Utilizare: $0 /etc/vsftpd.conf"
	exit 1;
fi

if [ ! -f "$filename" ]; then
	echo "EROARE: Fișierul '$filename' nu a fost găsit!"
	exit 1;
fi

echo "===RAPORT SECURITATE FTP: $fileame==="

perm=$(stat -c %a "$filename")
owner=$(stat -c %U "$filename")

echo "Permisiuni: $perm | Proprietar: $owner"

if [ "$perm" != "600" ] && [ "$perm" != "644" ]; then
    echo "[!!] ALERTA: Permisiuni nesigure! Recomandat 600."
fi
if [ "$owner" != "root" ]; then
    echo "[!!] ALERTA: Proprietarul nu este root! Risc de manipulare."
fi

echo "--------------------------------"

echo -e "\n==== ANALIZĂ OPȚIUNI CRITICE ===="

verifica_setare() {
setare=$1
valoare_buna=$2
mesaj_eroare=$3

actual=$(grep "^$setare=" "$filename" | tail -1 |cut -d'=' -f2)

if [ -z "$actual" ]; then
	echo "INFO: $setare: Nu este configurat (se foloseste setarea standard)."
elif [ "$actual" == "$valoare_buna" ]; then
	echo "[OK]. $setare este $actual."
else
	echo "[!!]ALERTA: $setare este $actual! $mesaj_eroare"
fi
}

verifica_setare "anonymous_enable" "NO" "Oricine se poate loga fără parolă!"
verifica_setare "chroot_local_user" "YES" "Lipsa de izolare! Utilizatorii pot vedea fișierele de sistem!"
verifica_setare "ssl_enable" "YES" "Parolele sunt trimise necriptat prin rețea!"
verifica_setare "local_enable" "YES" "Utilizatorii locali sunt blocați."
verifica_setare "write_enable" "YES" "Serverul este Read-Only (scriere dezactivată)."
verifica_setare "allow_writeable_chroot" "NO" "Risc securitate: scriere permisă în rădăcina chroot."
verifica_setare "max_clients" "50" "Fără limită de clienți (Risc atac DoS)."
verifica_setare "max_per_ip" "5" "Un singur IP poate ocupa toate conexiunile."
verifica_setare "listen" "YES" "Serverul nu rulează în mod standalone."
echo "---------------------------------------"

echo "=====Analiză duplicate:====="
duplicate=$(grep -v "^#" "$filename" | cut -d'=' -f1 | sort | uniq -d)

if [ -z "$duplicate" ]; then
    echo "[OK]Nu s-au găsit setări duplicate."
else
	for d in $duplicate; do
        	linii=$(grep -n "^$d=" "$filename" | cut -d':' -f1 | tr '\n' ',' | sed 's/,$//')
        	val_finala=$(grep "^$d=" "$filename" | tail -1 | cut -d'=' -f2)
        	echo "[ !! ] Directiva '$d' apare la liniile ($linii). Valoarea activă: $val_finala."
    	done
fi
echo "---------------------------------------"
echo "=== SFÂRȘIT RAPORT ==="
echo "---------------------------------------"
