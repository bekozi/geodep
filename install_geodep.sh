#!/bin/bash

# script installs package dependencies for postgis in a python virtual environment directory

## INSTALL SETTINGS -----------------------------------------

# path to directory where src files should be downloaded
DIRSRC=/usr/local/src
# path to src directory
INSTALLDIR=/usr/local
# versions of packages to install
PROJ=4.7.0
GEOS=3.2.2
GDAL=1.8.0
POSTGRES=8.4
POSTGIS=1.5.2

## DEPENDENT VARIABLES --------------------------------------

IPROJ=$INSTALLDIR/proj/$PROJ
IGEOS=$INSTALLDIR/geos/$GEOS
IGDAL=$INSTALLDIR/gdal/$GDAL
IPOSTGIS=$INSTALLDIR/postgis/$POSTGIS
POSTGIS_TEMPLATE=postgis-$POSTGIS-template

## FUNCTIONS ------------------------------------------------

fn_wget()
{
    wget $1
}

fn_untarnav()
{
    tar -xzvf $1
    cd $2
}

fn_unbznav()
{
    tar -xjf $1
    cd $2
}

fn_mksrcnav()
{
    foo=$DIRSRC/$1/$2
    mkdir -p $foo
    cd $foo
}

fn_ldconfig()
{
    sudo sh -c "echo $1'/lib' > /etc/ld.so.conf.d/$2.conf"
    sudo ldconfig
}

fn_install_proj()
{
    bname=proj-$PROJ
    fn_mksrcnav $b $PROJ
    fn_wget http://download.osgeo.org/proj/$bname.tar.gz
    fn_wget http://download.osgeo.org/proj/proj-datumgrid-1.5.zip
    fn_untarnav $bname.tar.gz $bname
    cd nad
    unzip ../../proj-datumgrid-1.5.zip
    cd ..
    mkdir -p $IPROJ
    sudo ./configure --prefix=$IPROJ
    sudo make
    sudo make install
    fn_ldconfig $IPROJ "proj"
}

fn_install_geos()
{
    bname=geos-$GEOS
    fn_mksrcnav "geos" $GEOS
    fn_wget http://download.osgeo.org/geos/$bname.tar.bz2
    fn_unbznav $bname.tar.bz2 $bname
    mkdir -p $IGEOS
    sudo ./configure --prefix=$IGEOS
    sudo make
    sudo make install
    fn_ldconfig $IGEOS "geos"
}

fn_install_gdal()
{
    bname=gdal-$GDAL
    fn_mksrcnav "gdal" $GDAL
    fn_wget http://download.osgeo.org/gdal/gdal-$GDAL.tar.gz
    fn_untarnav gdal-$GDAL.tar.gz $bname
    mkdir -p $IGDAL
    sudo ./configure --prefix=$IGDAL --with-geos=$IGEOS/bin/geos-config
    sudo make
    sudo make install
    sudo sh -c "echo $IGDAL'/lib' > /etc/ld.so.conf.d/gdal.conf"
    sudo ldconfig
}

fn_install_postgis()
{
    sudo apt-get install -y postgresql postgresql-server-dev-$POSTGRES libpq-dev
    sudo apt-get install -y libxml2 libxml2-dev
    #sudo apt-get install -y libcfitsio3 libcfitsio3-dev

    bname=postgis-$POSTGIS
    mkdir -p $IPOSTGIS
    cd $IPOSTGIS
    fn_wget http://postgis.refractions.net/download/postgis-$POSTGIS.tar.gz
    fn_untarnav postgis-$POSTGIS.tar.gz $bname
    sudo ./configure --with-geosconfig=$IGEOS/bin/geos-config --with-projdir=$IPROJ
    sudo make
    sudo make install

    sudo su -c "createdb $POSTGIS_TEMPLATE" - postgres 
    sudo su -c "createlang plpgsql $POSTGIS_TEMPLATE" - postgres 
    sudo -u postgres psql -d postgres -c "UPDATE pg_database SET datistemplate='true' WHERE datname='$POSTGIS_TEMPLATE';"  
    sudo -u postgres psql -d $POSTGIS_TEMPLATE -f /usr/share/postgresql/$POSTGRES/contrib/postgis-1.5/postgis.sql 
    sudo -u postgres psql -d $POSTGIS_TEMPLATE -f /usr/share/postgresql/$POSTGRES/contrib/postgis-1.5/spatial_ref_sys.sql
    sudo -u postgres psql -d $POSTGIS_TEMPLATE -c "GRANT ALL ON geometry_columns TO PUBLIC;"
    sudo -u postgres psql -d $POSTGIS_TEMPLATE -c "GRANT SELECT ON spatial_ref_sys TO PUBLIC;"
}

## MAIN -----------------------------------------------------

# upgrade system
sudo apt-get -y update
sudo apt-get -y upgrade
# install dependencies
sudo apt-get install -y gcc
sudo apt-get install -y g++
sudo apt-get install -y emacs23
sudo apt-get install -y wget

fn_install_proj
fn_install_geos
fn_install_postgis
fn_install_gdal
