#!/bin/sh

#export BUILD_VERSION=v1.0
buildroot=`pwd`

cd ${buildroot}/SOURCES

git clone git@github.com:ec-europa/joinup-dev.git Joinup-$BUILD_VERSION
cd Joinup-$BUILD_VERSION
git checkout tags/$RELEASE_TAG
echo X-build-id: $BUILD_VERSION > ./buildinfo.ini

cd web
cp -R ../../template/* ./
cd ..

rm -rf .gitignore
rm -rf .git
rm -rf rpmbuild

composer install

shopt -s extglob

mkdir Joinup-$BUILD_VERSION
mv !(Joinup-$BUILD_VERSION) Joinup-$BUILD_VERSION
tar -cvvzf ../Joinup-$BUILD_VERSION.tar.gz Joinup-$BUILD_VERSION/
rm -rf Joinup-$BUILD_VERSION

cd ${buildroot}/SPECS
rpmbuild -ba joinup.spec --define "_topdir ${buildroot}"

cd ${buildroot}/RPMS
cp -R noarch /mnt/shared/distribution/
rm -rf noarch
cd /mnt/shared/distribution/
createrepo . --no-database
