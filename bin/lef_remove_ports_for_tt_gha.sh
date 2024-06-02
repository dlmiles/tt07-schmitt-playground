#!/bin/bash -e
#
#
dir=$(dirname "$0")
export PATH="${dir}:$PATH"

myfile="tt_um_dlmiles_schmitt_playground"
mydir="${dir}/../lef"

if [ -f "${dir}/../gds/${myfile}.gds.n" ]
then
	mv -f "${dir}/../gds/${myfile}.gds" "${dir}/../gds/${myfile}.gds.o"
	mv -fv "${dir}/../gds/${myfile}.gds.n" "${dir}/../gds/${myfile}.gds"
fi

if [ -f "${dir}/../lef/${myfile}.lef.n" ]
then
	mv -f "${dir}/../lef/${myfile}.lef" "${dir}/../lef/${myfile}.lef.o"
	mv -fv "${dir}/../lef/${myfile}.lef.n" "${dir}/../lef/${myfile}.lef"
fi


if lef_remove_ports_for_tt_gha.pl "${mydir}/${myfile}.lef" > "${mydir}/${myfile}.lef.n"
then
	if [ ! -s "${mydir}/${myfile}.lef.n" ]
	then
		echo "ERROR: Check ${mydir}/${myfile}.lef is valid (new file looks empty)" 1>&2
		exit 1
	elif cmp -s "${mydir}/${myfile}.lef" "${mydir}/${myfile}.lef.n"
	then
		rm -f "${mydir}/${myfile}.lef.n" # cleanup
		echo "NOCHANGE: LEF file was not modified (no ports to remove)" 1>&2
		exit 0
	else
		if mv -fv "${mydir}/${myfile}.lef" "${mydir}/${myfile}.lef.o"
		then
			wc "${mydir}/${myfile}.lef.o"

			mv -iv "${mydir}/${myfile}.lef.n" "${mydir}/${myfile}.lef"

			wc "${mydir}/${myfile}.lef"

			# Usually the output is enough to remember what correct looks like
			diff -u "${mydir}/${myfile}.lef.o" "${mydir}/${myfile}.lef" | diffstat
		fi
	fi
else
	echo "ERROR: Check ${mydir}/${myfile}.lef is valid" 1>&2
	exit 1
fi
