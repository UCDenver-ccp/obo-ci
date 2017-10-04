#!/bin/bash -e

# Downloads the latest OWLTools-Runner jar and deploys it to the local Maven repository
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <work directory>]: MUST BE ABSOLUTE PATH. The base directory where all intermediate files will be stored."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
}

while getopts "d:m:h" OPTION; do
    case ${OPTION} in
        # The work directory
        d) WORK_DIRECTORY=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${WORK_DIRECTORY} || -z ${MAVEN} ]]; then
	echo "missing input arguments!!!!!"
	echo "work directory: ${WORK_DIRECTORY}"
	echo "path to Maven binary: $MAVEN"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

echo "Downloading OWLTools-Runner jar file to: ${WORK_DIRECTORY}"

URL=http://build.berkeleybop.org/userContent/owltools/OWLTools-Runner-0.3.0-SNAPSHOT.jar
wget -c -t 0 --timeout 60 --waitretry 10 -P ${WORK_DIRECTORY} ${URL}

mvn install:install-file -Dfile=${WORK_DIRECTORY}/OWLTools-Runner-0.3.0-SNAPSHOT.jar -DgroupId=org.bbop \
    -DartifactId=OWLTools-Runner -Dversion=0.3.0-SNAPSHOT -Dpackaging=jar