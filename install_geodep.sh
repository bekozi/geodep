#!/bin/bash

# script installs package dependencies for postgis in a python virtual environment directory

## INSTALL SETTINGS -----------------------------------------

# path to directory where src files should be downloaded
DIRSRC=/tmp/src
# path to virtual environment directory
DIRVENV=/tmp/virtual
# versions of packages to install
PROJ=4.7.0
GEOS=3.2.2
GDAL=1.8.0
POSTGRES=8.4
POSTGIS=1.5.3

## DEPENDENT VARIABLES --------------------------------------

VEBASE=$DIRVENV/bin
IPROJ=$VEBASE/proj/$PROJ
IGEOS=$VEBASE/geos/$GEOS
IGDAL=$VEBASE/gdal/$GDAL
IPOSTGIS=$VEBASE/postgis/$POSTGIS
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
    sudo sh -c "echo $1/lib > /etc/ld.so.conf.d/proj.conf"
    sudo ldconfig
}

fn_install_proj()
{
    b="proj"
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
}

fn_install_geos()
{
    b="geos"
    bname=geos-$GEOS
    fn_mksrcnav "geos" $GEOS
    fn_wget http://download.osgeo.org/geos/$bname.tar.bz2
    fn_unbznav $bname.tar.bz2 $bname
    mkdir -p $IGEOS
    sudo ./configure --prefix=$IGEOS
    sudo make
    sudo make install
}

fn_install_gdal()
{
    b="gdal"
    bname=gdal-$GDAL
    fn_mksrcnav $b $GDAL
    fn_wget http://download.osgeo.org/gdal/gdal-$GDAL.tar.gz
    fn_untarnav gdal-$GDAL.tar.gz $bname
    mkdir -p $IGDAL
    sudo ./configure --prefix=$IGDAL --with-geos=$IGEOS/bin/geos-config
    sudo make
    sudo make install
}

fn_install_postgis()
{
    sudo apt-get install -y postgresql postgresql-server-dev-$POSTGRES libpq-dev
    b="postgis"
    bname=$b-$POSTGIS
    fn_mksrcnav $b $POSTGIS
    fn_wget http://postgis.refractions.net/download/postgis-$POSTGIS.tar.gz
    fn_untarnav postgis-$POSTGIS.tar.gz $bname
    mkdir -p $IPOSTGIS
    sudo ./configure --prefix=$IPOSTGIS --with-geos=$IGEOS/bin/geos-config --with-projdir=$IPROJ
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
sudo apt-get upgrade
# install dependencies
sudo apt-get install -y gcc
sudo apt-get install -y g++
sudo apt-get install -y emacs23
sudo apt-get install -y wget

fn_install_proj
fn_install_geos
fn_install_gdal
fn_install_postgis