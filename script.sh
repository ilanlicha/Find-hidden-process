function dumpPid {
        pid=$1
        batchtemp=$(mktemp -t XXXXXX.gdb) && \
        cat >$batchtemp<<EOF && gdb -p $pid --batch --command=$batchtemp # 2>/dev/null | head -n 2 | tail -n 1
gcore /tmp/dump-$pid.core
quit
EOF
        errnum=$?
        rm $batchtemp 2>/dev/null
        if [ "$errnum" -ne 0 ] ; then
                false
        fi
}

function findPid {
	umount /proc/$pid
	DATE_CREATION=$(ps -eo lstart,cmd,pid | grep $pid |  grep -v grep | perl -pe 's/20(\d{2}).*$/20$1/')
	DATE_DETECTION=$(date +%A' '%d' '%B' '%H:%m:%S' '%Y | sed 's/\(.\)/\U\1/')
	FICHIERS_OUVERTS=$(ls -l /proc/$pid/fd | awk '{ print $11 }' | sed -e '/^$/d')
	PORT=$(ss -taupen 2>/dev/null | grep $pid | awk '{ print $5 }' | sed -E 's/^([0-9]{1,3}.){4}//')
	LIBS=$(cat /proc/$pid/maps | awk '{print $6}' | sort | uniq | perl -pe 's/^\n$//g' | grep '\.so')
	IMAGE_FILE=$(file /proc/$pid/exe | awk '{ print $5 }')
	ARGS=$(cat /proc/$pid/cmdline | perl -pe 's/\x00/ /g')
	ENV_VARS=$(cat /proc/$pid/environ | tr "\x00" "\n" | perl -pe 's/\x00/\n/g')

	echo -e "\n"
	echo -e "\n----------------------------------------------------------"
	echo -e "\n                       PID $pid"
        echo -e "\n----------------------------------------------------------"

	echo -e "Date de création du processus : $DATE_CREATION\n"
	echo -e "Processus détécté le : $DATE_DETECTION\n"

	echo -e "Liste des fichiers ouverts :"
	for fichier in $FICHIERS_OUVERTS
	do
	        echo $fichier
	done
	echo -e "\n"

	if [ "$PORT" = "" ] ; then
		echo -e "Port réseau : Pas de port réseau\n"
	else
		echo -e "Port réseau : $PORT\n"
	fi

	echo -e "Liste des bibliothèques en mémoire :"
	for lib in $LIBS
        do
                echo $lib
        done
        echo -e "\n"

	echo -e "Fichier imagefile du processus : $IMAGE_FILE\n"

	echo -e "Liste des arguments du programme :"
	for arg in $ARGS
	do
		echo $arg
	done
        echo -e "\n"

	echo -e "Liste des variables d'environnement du programme :"
	for var in $ENV_VARS
	do
	        echo $var
	done
        echo -e "\n"

	echo -e "Dump mémoire du processus :"
	dumpPid $pid
}

PIDS=$(mount | grep -E "\/proc\/([0-9]{1,4})" | awk '{ print $3 }' | sed 's/\/proc\///')

for pid in $PIDS
do
        findPid $pid
done

echo -e "\n"
echo -e "\n----------------------------------------------------------"
echo -e "\n                    FIN DE PROGRAMME"
echo -e "\n----------------------------------------------------------"
