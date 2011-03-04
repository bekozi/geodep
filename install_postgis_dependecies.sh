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

## DEPENDENT VARIABLES --------------------------------------

VEBASE=$DIRVENV/bin
IPROJ=$VEBASE/proj/$PROJ
IGEOS=$VEBASE/geos/$GEOS
IGDAL=$VEBASE/gdal/$GDAL

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

## MAIN -----------------------------------------------------

# install dependencies
apt-get install wget

fn_install_proj()
fn_install_geos()
fn_install_gdal()
