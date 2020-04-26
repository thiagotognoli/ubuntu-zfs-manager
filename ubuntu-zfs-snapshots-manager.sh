#!/bin/bash

function checkRoot() {
    if [ "$EUID" -ne 0 ]
        then echo "Please run as root"
        exit
    fi
}

checkRoot

declare -A meses
for mes in {1..12}
do
	mesTexto="$(date -d "1980-$mes-01" "+%b")"
	printf -v mesPad "%02d" $mes
	meses[$mesTexto]=$mesPad
done


function getSnapshots() {
	
	declare -A snapshotNames
	declare -A snapshotData
	declare -A snapshotDataNum
	declare -A snapshotVolumes
	
	while read -r line; do 
		fullName="$(echo "$line" | cut -d "	" -f 1)";
		volName="$(echo "$fullName" | sed -r "s/([^@]*)(@)(.*)/\1/")";
		snapshotName="$(echo "$fullName" | sed -r "s/([^@]*)(@)(.*)/\3/")";
		data="$(echo "$line" | cut -d "	" -f 2)";
		data="$(sed -r -e "s/( )([ ]+)/\1/g" <<< "$data")"

		readarray -d " " -t dataSplit  < <(printf '%s' "$data")
		
		dataAno="${dataSplit[4]}"

		dataMes="${dataSplit[1]}"
		dataMes="${meses[$dataMes]}"
		
		dataHora="$(echo "${dataSplit[3]}" | cut -d ":" -f 1)"
		printf -v dataHora "%02d" $dataHora
		
		dataMinuto="$(echo "${dataSplit[3]}" | cut -d ":" -f 2)"
		
		#snapshotKey="${dataAno}-${dataMes}-${dataSplit[2]}-${dataSplit[3]}@$snapshotName"
		snapshotKey="$snapshotName"
		if [[ -z "${snapshotDataNum[${snapshotKey}]}" ]]; then
			snapshotDataNum["$snapshotKey"]="${dataAno}-${dataMes}-${dataSplit[2]} ${dataHora}:${dataMinuto}";
			snapshotData["$snapshotKey"]="$(date -d "${snapshotDataNum[$snapshotKey]}" "+%x %X")"
			eval "snapshotVol_$snapshotKey=()"
		fi
		eval "snapshotVol_$snapshotKey+=($volName)"
		snapshotNames["$snapshotKey"]="$snapshotName"
		#snapshotData["$snapshotKey"]="$data"
		optionsToShow+=(FALSE "$snapshotName" "$data")
		
		
	
		#echo "$fullName";
		#echo "$volName";
		#echo "$snapshotName";
		#echo "$data";
	done <<< "$(zfs list -H -o name,creation,avail,used,usedsnap,usedds,usedrefreserv,usedchild -t snapshot)"


	snapshotDataNumTmp="$(for k in "${!snapshotDataNum[@]}"
	do
		echo ${snapshotDataNum["$k"]}'@'$k
	done | sort -n -k3)"
	
	snapshotOrdered=()
	while read -r line; do
		readarray -d "@" -t dataSplit < <(printf '%s' "$line")
		#snapshotDataNumOrd["${dataSplit[1]}"]="${dataSplit[0]}"
		snapshotOrdered+=("${dataSplit[1]}")
	done <<< "$snapshotDataNumTmp"


	optionsToShow=()
	for snapshot in "${snapshotOrdered[@]}";
	do
		#echo "----"
		#echo "${snapshotDataNum[$snapshot]} - $snapshot"
		#eval "volumes=\$(printf \",%s\" \"\${snapshotVol_$snapshot[@]}\")"
		#eval "volumes=$( IFS=\",\" ; echo \"\${snapshotVol_$snapshot[*]}\" )"
		eval "local IFS=\",\"; volumes=\"\${snapshotVol_$snapshot[*]}\""
		#echo "$volumes"
		
		optionsToShow+=(FALSE "${snapshotNames[$snapshot]}" "${snapshotData[$snapshot]}" "$volumes");
	done	
	
	snapshotsSelected=$(zenity  --list  --width=800 --height=640 \
		--checklist \
		--text "Snapshots" \
	        --column "Deletar" \
        	--column "Nome" \
	        --column "Data" \
	        --column "Volumes" \
        	"${optionsToShow[@]}")	
	echo "$snapshotsSelected"
	
	
	postCommand="echo 'Sem Snap para excluir'"
	local IFS="|"
	for snapshot in $snapshotsSelected;
	do
		postCommand="/usr/libexec/zsys-system-autosnapshot update-menu"
		zsysctl state remove -f -s "$snapshot";
		while read line; do
			line=$(echo $line | cut -d " " -f 1);
			echo "Excluindo volume/snap $line";
			zfs destroy "$line";
		done <<< $(zfs list -t snapshot | grep -E "^([^ ]*@$snapshot)")
	done
    	eval "$postCommand"
}


function createSnapshot() {
	echo "Criando Snapshot $1"
	zsysctl state save -s $1
	main
}

function createSnapshotNamed() {
	snapShotName=$(zenity --entry --text="Qual nome do snapshot?")
	cancel=$?
	if [[ $cancel = 1 ]] ;
	then
		echo "Cancelado!";
		main
	else
		if [ -z "$snapShotName" ];
		then
			echo "Nome Vazio!";
			createSnapshotNamed
		else
			createSnapshot "$snapShotName"
		fi
	fi
}

function listSnapshot() {
	echo "Listando Snapshots"
	getSnapshots
	main
}

function main () {
	mainOptionsTitle=();
	mainOptionsCommands=();

	mainOptionsTitle+=("Criar Snapshot")
	mainOptionsCommands+=("createSnapshot");
	mainOptionsTitle+=("Criar Snapshot Nomeado")
	mainOptionsCommands+=("createSnapshotNamed");
	mainOptionsTitle+=("Listar Snapshots")
	mainOptionsCommands+=("listSnapshot");


	optionSelected=$(zenity  --list  --width=800 --height=640 \
		--text "Geranciador de Snapshots ZFS" \
	        --column "Ação" \
        	"${mainOptionsTitle[@]}")    

	echo "$optionSelected"

	defaulCall=""
	mainOptionsLength=${#mainOptionsCommands[@]}
	local IFS="|"
	for command in "$optionSelected";
	do
		for (( i=0; i<${mainOptionsLength}; i++ ));
	        do
        	    [[ "${mainOptionsTitle[$i]}" == "$command" ]] && eval "${mainOptionsCommands[$i]}"
        	done
	done

	#eval "${defaulCall}"
	#THERE=$?

}

main   

