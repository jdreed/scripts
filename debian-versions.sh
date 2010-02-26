#!/bin/sh
DEBIAN_CODES="etch lenny squeeze hardy intrepid jaunty karmic lucid"
gettag() {
    case "$1" in
	etch)
	    echo "~debian4.0"
	    ;;
	lenny)
	    echo "~debian5.0"
	    ;;
	squeeze)
	    echo "~debian6.0~0.2"
	    ;;
	hardy)
	    echo "~ubuntu8.04"
	    ;;
	intrepid)
	    echo "~ubuntu8.10"
	    ;;
	jaunty)
	    echo "~ubuntu9.04"
	    ;;
        karmic)
            echo "~ubuntu9.10"
            ;;
	lucid)
	    echo "~ubuntu10.04~0.1"
	    ;;
	versions)
	    echo "$DEBIAN_CODES"
	    ;;
	*)
	    echo "error"
	    return 1
	    ;;
    esac
}
