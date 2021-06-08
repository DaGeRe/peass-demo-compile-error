#!/bin/bash

DEMO_PROJECT_NAME=demo-project-compile-error

git clone https://github.com/mai13drd/demo-project-compile-error && \
    cd  demo-project-compile-error && \
    git reset --hard 577bb7f03abbb8855232fe22adac9966c7c178fb && \
    cd ..

git clone https://github.com/DaGeRe/peass.git && \
	cd peass && \
	./mvnw clean install -DskipTests -V

DEMO_HOME=$(pwd)/../$DEMO_PROJECT_NAME
DEMO_PROJECT_PEASS=../"$DEMO_PROJECT_NAME"_peass
EXECUTION_FILE=results/execute_"$DEMO_PROJECT_NAME".json
DEPENDENCY_FILE=results/deps_"$DEMO_PROJECT_NAME".json
CHANGES_DEMO_PROJECT=results/changes_"$DEMO_PROJECT_NAME".json
PROPERTY_FOLDER=results/properties_"$DEMO_PROJECT_NAME"/

VERSION="$(cd "$DEMO_HOME" && git rev-parse HEAD)"
echo "VERSION: $VERSION"

# It is assumed that $DEMO_HOME is set correctly and PeASS has been built!
echo ":::::::::::::::::::::SELECT:::::::::::::::::::::::::::::::::::::::::::"
./peass select -folder $DEMO_HOME

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#Measure again with a version which has no compile error
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
cd $DEMO_HOME && git pull
VERSION="$(cd "$DEMO_HOME" && git rev-parse HEAD)"
echo "VERSION: $VERSION"

cd ../peass

# It is assumed that $DEMO_HOME is set correctly and PeASS has been built!
echo ":::::::::::::::::::::SELECT:::::::::::::::::::::::::::::::::::::::::::"
./peass select -folder $DEMO_HOME

if [ ! -f "$EXECUTION_FILE" ]
then
    echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    echo "$EXECUTION_FILE could not be found!"
    echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    exit 1
fi

echo ":::::::::::::::::::::MEASURE::::::::::::::::::::::::::::::::::::::::::"
./peass measure -executionfile $EXECUTION_FILE -folder $DEMO_HOME -iterations 1 -warmup 0 -repetitions 1 -vms 2

echo "::::::::::::::::::::GETCHANGES::::::::::::::::::::::::::::::::::::::::"
./peass getchanges -data $DEMO_PROJECT_PEASS -dependencyfile $DEPENDENCY_FILE

#Check, if $CHANGES_DEMO_PROJECT contains the correct commit-SHA
TEST_SHA=$(grep -A1 'versionChanges" : {' $CHANGES_DEMO_PROJECT | grep -v '"versionChanges' | grep -Po '"\K.*(?=")')
if [ "$VERSION" != "$TEST_SHA" ]
then
    echo "commit-SHA ("$VERSION") is not equal to the SHA in $CHANGES_DEMO_PROJECT ("$TEST_SHA")"
    cat results/statistics/"$DEMO_PROJECT_NAME".json
    exit 1
else
    echo "$CHANGES_DEMO_PROJECT contains the correct commit-SHA."
fi

echo "::::::::::::::::::::SEARCHCAUSE:::::::::::::::::::::::::::::::::::::::"
./peass searchcause -vms 5 -iterations 1 -warmup 0 -version $VERSION \
    -test de.dagere.peass.ExampleTest\#test \
    -folder $DEMO_HOME \
    -executionfile $EXECUTION_FILE

echo "::::::::::::::::::::VISUALIZERCA::::::::::::::::::::::::::::::::::::::"
./peass visualizerca -data $DEMO_PROJECT_PEASS -propertyFolder $PROPERTY_FOLDER

#Check, if a slowdown is detected for Callee#innerMethod
STATE=$(grep -A21 '"call" : "de.dagere.peass.Callee#innerMethod",' results/$VERSION/de.dagere.peass.ExampleTest_test.js \
    | grep '"state" : "SLOWER",' \
    | grep -o 'SLOWER')
if [ "$STATE" != "SLOWER" ]
then
    echo "State for Callee#innerMethod in de.dagere.peass.ExampleTest_test.js has not the expected value SLOWER, but was $STATE!"
    cat results/$VERSION/de.dagere.peass.ExampleTest_test.js
    exit 1
else
    echo "Slowdown is detected for Callee#innerMethod."
fi

SOURCE_METHOD_LINE=$(grep "Callee.method1_" results/$VERSION/de.dagere.peass.ExampleTest_test.js -A 3 \
    | head -n 3 \
    | grep innerMethod)
if [[ "$SOURCE_METHOD_LINE" != *"innerMethod();" ]]
then
    echo "Line could not be detected - source reading probably failed."
    echo "SOURCE_METHOD_LINE: $SOURCE_METHOD_LINE"
    exit 1
else
    echo "SOURCE_METHOD_LINE is correct."
fi
