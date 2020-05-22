#!/bin/sh
set -e

PKG=$(pkg_info | grep -E '^(apache-ant|jdk|openal|maven|rsync|lwjgl|xz|jna)\-' | wc -l)
if [ "$PKG" -eq 8 ]
then
	echo "Packages installed: OK"
else
	echo "Packages missing. Required packages are apache-ant, jdk, openal, maven, rsync, lwjgl, xz, jna"
	exit 1
fi

if [ ! -f Unciv.jar ]
then
	ftp https://github.com/yairm210/Unciv/releases/download/3.8.11/Unciv.jar
fi

# extract
mkdir unjar
cd unjar
GAME_FOLDER=$PWD
/usr/local/jdk*/bin/jar xvf ../Unciv.jar

# remove java files
rm -fr com/badlogic

# copy libs
cp /usr/local/share/lwjgl/liblwjgl64.so liblwjgl64.so
cp /usr/local/lib/libopenal.so.* libopenal64.so 

# download and extract libgdx-openbsd
ftp https://perso.pw/gaming/libgdx199-openbsd-0.0.tar.xz
unxz < libgdx199-openbsd-0.0.tar.xz | tar xvf -

# build some so files
cd $GAME_FOLDER/libgdx-openbsd/gdx/jni && ant -f build-openbsd64.xml
cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-freetype/jni && ant -f build-openbsd64.xml 

# copy so files
cd $GAME_FOLDER
find libgdx-openbsd -type f -name '*.so' -exec cp {} . \;

cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-jnigen && mvn package && \
	rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/gdx/ && mvn package && \
	rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/backends/gdx-backend-lwjgl/ && mvn package && \
	rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-freetype && mvn package && \
	rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-controllers/gdx-controllers && \
	mvn package && rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-controllers/gdx-controllers-desktop && \
	mvn package && rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-tools && mvn package && \
	rsync -avh target/classes/com/ $GAME_FOLDER/com/

mkdir $GAME_FOLDER/com/sun/jna/openbsd-x86-64
cd $GAME_FOLDER/com/sun/jna/openbsd-x86-64 && \
	/usr/local/jdk*/bin/jar xvf /usr/local/share/java/classes/jna-platform.jar

# Java classes without discord-rpc and com.badlogic.gdx.Input.setCatchKey
cd $GAME_FOLDER
ftp -o com/unciv/app/desktop/DesktopLauncher.class \
	https://github.com/reivyr/openbsd-unciv/raw/master/classes/DesktopLauncher.class
ftp -o com/unciv/UncivGame.class \
	https://github.com/reivyr/openbsd-unciv/raw/master/classes/UncivGame.class

echo "You can run the game with the following command in the 'unjar' directory:"
echo "/usr/local/jdk-1.8.0/bin/java -Dsun.java2d.dpiaware=true com.unciv.app.desktop.DesktopLauncher"
