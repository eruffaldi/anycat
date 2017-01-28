#!/bin/bash
#
# Emanuele Ruffaldi 2016
#
# Decompresses many formats invoking the correct utility or using the extension of file
#
# anycat [-mode] input
#	where mode can be: jzJlL4ys some of which are in tar
#
# anycat [-a subfile] input.tar[.comp]
#	expands the subfile
# anycat [-a subfile] input.zip
#	expands the subfile
#
# TODO: decompress images e.g. jpeg png needs special argument
#
# Latest tar 1.29 supports: gzip, bzip2, lzip, xz, lzma, lzop, compress
# https://www.gnu.org/software/tar/manual/html_node/gzip.html
#
# Correspondence between extension/format/argument/technique as in tar
# .gz    gzip   z      LZ77
# .Z     compress y    lempel-zip
# .bz2   bzip2  j      BZIP2
# .xz    xz     J      LZMA
# .lzma  lzma   l (--lzma in tar) LZMA
# .lzo   lzop   L (--lzop in tar) LZMA
# .lz4   lz4    4 (not tar)       LZMA
# .lz    lzip   Z (--lzip in tar) LZMA
# .zst   zstd   s (not in tar)    ZSTD
# .zip   zip                      various LZ78
MODE=
while getopts ":ha:jJlL4yzZ" opt; do
  case $opt in
  	h)
      echo "-h help"  >&2
      echo "-a expand subfile" >&2
      echo "-jJlL4yzZs for forcing the compression mode (bzip2,xz,lzma,lzop,lz4,compress,gzip,lzip,zstd)" >&2
      exit 0
      ;;
  	a)
      SUBFILE=$OPTARG
      echo "SUBFILE",$OPTARG >&2
      ;;
    j) 
      MODE=j
      ;;
    z)
	  MODE=z
	  ;;
	y)
	  MODE=y
	  ;;
	s)
	  MODE=s
	  ;;
	l)
	  MODE=l
	  ;;
	L)
	  MODE=l
	  ;;
	J)
	  MODE=J
	  ;;
	4)
	  MODE=4
	  ;;
	Z)
	  MODE=Z
	  ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))
NAME="$1"
if [ ${SUBFILE} ]; then
	if [ ${SUBFILE} == "-" ]; then
		SUBFILE=
	fi
	#echo "doing ${NAME} with subfolder ${SUBFILE}. Mode ignored"
	if [ ${NAME: -4} == ".tar" ]; then
		tar xf ${NAME} -O ${SUBFILE}
	elif [ ${NAME: -7} == ".tar.gz" ]; then
		tar zxf ${NAME} -O ${SUBFILE}
	elif [ ${NAME: -7} == ".tar.xz" ]; then
		tar Jxf ${NAME} -O ${SUBFILE}
	elif [ ${NAME: -7} == ".tar.lz" ]; then
		tar xf ${NAME} --lzip -O ${SUBFILE}
	elif [ ${NAME: -8} == ".tar.bz2" ]; then
		tar jxf ${NAME} -O ${SUBFILE}
	elif [ ${NAME: -6} == ".tar.Z" ]; then
		tar yxf ${NAME} -O ${SUBFILE}
	elif [ ${NAME: -9} == ".tar.lzma" ]; then
		tar xf ${NAME} --lzma -O ${SUBFILE}
	elif [ ${NAME: -8} == ".tar.lzo" ]; then
		tar xf ${NAME} --lzop -O ${SUBFILE}
	elif [ ${NAME: -4} == ".zip" ]; then
		unzip -p ${NAME} ${SUBFILE}
	else
		echo "unsupported compressed mode for file ${NAME}" >&2
		exit 1
	fi
else
	if  [[ $MODE = *[!\ ]* ]]; then
		MODE=${MODE}
	elif [ ${NAME: -3} == ".gz" ]; then
		MODE=z
	elif [ ${NAME: -4} == ".lz4" ]; then
		MODE=4
	elif [ ${NAME: -4} == ".bz2" ]; then
		MODE=j
	elif [ ${NAME: -2} == ".Z" ]; then
		MODE=y
	elif [ ${NAME: -3} == ".xz" ]; then
		MODE=J
	elif [ ${NAME: -3} == ".lz" ]; then
		MODE=Z
	elif [ ${NAME: -4} == ".zst" ]; then
		MODE=s
	elif [ ${NAME: -5} == ".lzma" ]; then
		MODE=l
	elif [ ${NAME: -4} == ".lzo" ]; then
		MODE=L
	fi
	#echo "doing ${NAME} - Mode ${MODE}" >&2

	case $MODE in
		z)
			gunzip -c "${NAME}"
			;;
		Z)
			lzip -dc "${NAME}"
			;;
		4)
			lz4cat -c "${NAME}"
			;;
	    j)
			bunzip2 -c "${NAME}"
			;;
		y)
			uncompress -c "${NAME}"
			;;
		J)
			unxz -c "${NAME}"
			;;
		l)
			unlzma -c "${NAME}"
			;;	
	        L)
			lzop -dc "${NAME}"
			;;
	        s)
			zstdcat "${NAME}"
			;;
		\?)
			cat $1
			;;
	esac
fi