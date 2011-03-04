#!/usr/bin/env bash
## script for installing packages used for a geodjango server
## Example usage:
##   bash 01_install_geospatial_packages.sh >& 01_install_geospatial_packages.log

echo "started at:"; date

## load the script that contains SetEnvVar
#. /usr/local/adm/mtrifuncs.sh 

# set the root directory used for building from source
SRCDIR=/usr/local/src

GEOS_VER=3.2.2
GEOS_PATH=$SRCDIR/geos/$GEOS_VER
PROJ_VER=4.7.0
PROJ_PATH=$SRCDIR/proj/$PROJ_VER
GDAL_VER=1.7.2
GDAL_PATH=/usr/local/gdal/$GDAL_VER
LIBGEOTIFF_VER=1.2.5
LIBGEOTIFF_PATH=/usr/local/libgeotiff/$LIBGEOTIFF_VER
POSTGRESQL_VER=8.4
POSTGIS_VER=1.5.2
POSTGIS_PATH=$SRCDIR/postgis/$POSTGIS_VER
POSTGIS_TEMPLATE=postgis-$POSTGIS_VER-template
#LIBKML_VER=1.2.0
#LIBKML_SRC=libkml-$LIBKML_VER.tar.gz
#LIBKML_SRC_URL=http://libkml.googlecode.com/files/$LIBKML_SRC
#LIBKML_PATH=/usr/local/libkml
#PYLIBKML_VER=trunk
#PYLIBKML_PATH=/usr/local/pylibkml
DJANGO_PATH=$SRCDIR/django
PYKML_PATH=$SRCDIR/python-kml
BITBUCKET_USER=bekozi
DIST_PKGS=/usr/lib/python2.6/dist-packages
HDF5_VER=1.8.5-patch1
HDF5_PATH=$SRCDIR/hdf5/$HDF5_VER
NETCDF4_VER=4.1.1
NETCDF4_PATH=$SRCDIR/netCDF4/$NETCDF4_VER
NETCDF4_PYTHON_VER=0.9.2
NETCDF4_PYTHON_PATH=$SRCDIR/netcdf4-python/$NETCDF4_PYTHON_VER


sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installing the essential build packages"
sudo apt-get install -y build-essential

echo "Installing version control tools..."
sudo apt-get install -y subversion

echo "Installing g++"
sudo apt-get install -y g++

echo "Installing python dev..."
sudo apt-get install -y python-all-dev

echo "Installing python scientific"
sudo apt-get install -y python-scientific

echo "Installing python numpy"
sudo apt-get install -y python-numpy

echo "Installing RPy"
sudo apt-get install -y python-rpy

echo "Installing libxml2"
sudo apt-get install -y libxml2 libxml2-dev

echo "Installing PostgreSQL $POSTGRESQL_VER..."
sudo apt-get install -y postgresql postgresql-server-dev-$POSTGRESQL_VER python-psycopg2 flex libpq-dev

echo "Installing libcfitsio..."
sudo apt-get install -y libcfitsio3 libcfitsio3-dev
CFITSIO_PATH=/usr/lib

echo "Installing libnetcdf4..."
sudo apt-get install -y libnetcdf4 libnetcdf-dev
NETCDF_PATH=/usr/lib

echo "Installing libtiff4..."
sudo apt-get install -y libtiff4 libtiff4-dev
LIBTIFF_PATH=/usr/lib

echo "Installing Apache..."
sudo apt-get install -y apache2 apache2.2-common apache2-mpm-worker apache2-threaded-dev libapache2-mod-wsgi python-dev

echo "###################################################################"
echo "Building and installing Proj..."
echo "###################################################################"
mkdir -p $SRCDIR/proj
cd $SRCDIR/proj
wget http://download.osgeo.org/proj/proj-$PROJ_VER.tar.gz
wget http://download.osgeo.org/proj/proj-datumgrid-1.5.zip
tar xzf proj-$PROJ_VER.tar.gz
cd proj-$PROJ_VER/nad
unzip ../../proj-datumgrid-1.5.zip
cd ..
./configure --prefix=$PROJ_PATH >& log_proj_configure.out
make >& log_proj_make.out
make install >& log_proj_make_install.out
sudo sh -c "echo $PROJ_PATH'/lib' > /etc/ld.so.conf.d/proj.conf"
sudo ldconfig
# QUICK TEST: search the shared libraries
#    sudo ldconfig -v | grep proj/
# This should return a path such as:
#    /usr/local/proj/4.7.0/lib

echo "###################################################################"
echo "Building and installing GEOS..."
echo "###################################################################"
sudo mkdir -p $GEOS_PATH
cd $GEOS_PATH
sudo wget http://download.osgeo.org/geos/geos-$GEOS_VER.tar.bz2
sudo tar xjf geos-$GEOS_VER.tar.bz2
cd geos-$GEOS_VER
./configure --prefix=$GEOS_PATH/geos-$GEOS_VER >& log_geos_configure.out
make >& log_geos_make.out
make install >& log_geos_make_install.out
#NOTE: PostGIS install fails during the make install step if the GEOS library
#path has not bee added to ldconfig 
sudo sh -c "echo $GEOS_PATH'/lib' > /etc/ld.so.conf.d/geos.conf" 
sudo ldconfig
# QUICK TEST: search the shared libraries
#    sudo ldconfig -v | grep geos/

echo "###################################################################"
echo "Building and installing PostGIS..."
echo "###################################################################"
mkdir -p $POSTGIS_PATH
cd $POSTGIS_PATH
wget http://postgis.refractions.net/download/postgis-$POSTGIS_VER.tar.gz
tar xzf postgis-$POSTGIS_VER.tar.gz
cd postgis-$POSTGIS_VER
./configure --prefix=$POSTGIS_PATH --with-geosconfig=$GEOS_PATH/geos-$GEOS_VER/bin/geos-config --with-projdir=$PROJ_PATH >& log_postgis_configure.out
make >& log_postgis_make.out
# PostGIS tries to install files in:
#     /usr/share/postgresql/$POSTGRESQL_VER/contrib and 
#     /usr/lib/postgresql/$POSTGRESQL_VER/lib
#     /usr/lib/postgresql/$POSTGRESQL_VER/bin
sudo make install >& log_postgis_make_install.out
# QUICK TEST: this should have installed files in the PostgreSQL share 
# directory: /usr/share/postgresql/$POSTGRESQL_VER/contrib

echo "###################################################################"
echo 'Creating a PostGIS Template Database'
echo "###################################################################"
sudo su -c "createdb $POSTGIS_TEMPLATE" - postgres 
sudo su -c "createlang plpgsql $POSTGIS_TEMPLATE" - postgres 

echo 'Configuring PostGIS Template and Setting Permissions'
sudo -u postgres psql -d postgres -c "UPDATE pg_database SET datistemplate='true' WHERE datname='$POSTGIS_TEMPLATE';"  
sudo -u postgres psql -d $POSTGIS_TEMPLATE -f /usr/share/postgresql/$POSTGRESQL_VER/contrib/postgis-1.5/postgis.sql 
sudo -u postgres psql -d $POSTGIS_TEMPLATE -f /usr/share/postgresql/$POSTGRESQL_VER/contrib/postgis-1.5/spatial_ref_sys.sql
sudo -u postgres psql -d $POSTGIS_TEMPLATE -c "GRANT ALL ON geometry_columns TO PUBLIC;"
sudo -u postgres psql -d $POSTGIS_TEMPLATE -c "GRANT SELECT ON spatial_ref_sys TO PUBLIC;"
# QUICK TEST: sudo -u postgres psql $POSTGIS_TEMPLATE -c "select postgis_full_version();"

echo "###################################################################"
echo "Building and Installing libgeotiff..."
echo "###################################################################"
#sudo apt-get install -y libgeotiff1.2
mkdir -p $SRCDIR/libgeotiff
cd $SRCDIR/libgeotiff
wget ftp://ftp.remotesensing.org/pub/geotiff/libgeotiff/libgeotiff-$LIBGEOTIFF_VER.tar.gz
tar xzf libgeotiff-$LIBGEOTIFF_VER.tar.gz
cd libgeotiff-$LIBGEOTIFF_VER
# the --with-ld-shared options is used to the hidden symbol error
# ref: http://mateusz.loskot.net/2008/07/31/libgeotiff-lesson-for-today/
./configure --prefix=$LIBGEOTIFF_PATH --with-libtiff=$LIBTIFF_PATH --with-proj=$PROJ_PATH --with-ld-shared="gcc -shared" >& log_libgeotiff_configure.out
make >& log_libgeotiff_make.out
make install >& log_libgeotiff_make_install.out
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LIBGEOTIFF_PATH/lib
#echo LD_LIBRARY_PATH=$LD_LIBRARY_PATH
sudo sh -c "echo $LIBGEOTIFF_PATH/lib > /etc/ld.so.conf.d/libgeotiff.conf"
sudo ldconfig
# QUICK TEST: search the shared libraries
#    sudo ldconfig -v | grep libgeotiff/
# This should return a path such as:
#    /usr/local/libgeotiff/1.2.5/lib


echo "###################################################################"
echo "Building and installing GDAL..."
echo "###################################################################"
mkdir -p $SRCDIR/gdal
cd $SRCDIR/gdal
wget http://download.osgeo.org/gdal/gdal-$GDAL_VER.tar.gz
tar xzf gdal-$GDAL_VER.tar.gz
cd gdal-$GDAL_VER
./configure --prefix=$GDAL_PATH --with-python --with-geos=$GEOS_PATH/geos-$GEOS_VER/bin/geos-config --with-cfitsio=$CFITSIO_PATH --with-netcdf=$NETCDF_PATH --with-geotiff=$LIBGEOTIFF_PATH >& log_gdal_configure.out
make >& log_gdal_make.out
make install >& log_gdal_make_install.out
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GDAL_PATH/lib
#echo LD_LIBRARY_PATH=$LD_LIBRARY_PATH
sudo sh -c "echo $GDAL_PATH/lib > /etc/ld.so.conf.d/gdal.conf"
sudo ldconfig
# add the GDAL Python files to the Python path
sh -c "echo /usr/local/gdal/1.7.1/lib/python2.6/site-packages/ > /usr/local/lib/python2.6/dist-packages/gdal.pth"
# QUICK TEST: search the shared libraries
#    sudo ldconfig -v | grep gdal/
# This should return a path such as:
#    /usr/local/libgeotiff/1.7.1/lib

echo "###################################################################"
echo "Installing Django..."
echo "###################################################################"
mkdir $DJANGO_PATH
svn co http://code.djangoproject.com/svn/django/trunk $DJANGO_PATH/trunk
cd $DJANGO_PATH/trunk
python setup.py install
#ln -s /usr/local/django/trunk/django/bin/django-admin.py /usr/local/bin/django-admin.py
#mkdir -p ~/.local/lib/python2.6/site-packages
#sh -c "echo /usr/local/django/trunk > ~/.local/lib/python2.6/site-packages/django.pth"

echo "###################################################################"
echo "Installing python-kml"
echo "###################################################################"
hg clone https://$BITBUCKET_USER@bitbucket.org/tylere/python-kml $PYKML_PATH
sh -c "echo $PYKML_PATH > $DIST_PKGS/python-kml.pth"

#echo "###################################################################"
#echo "Building and installing libkml..."
#echo "###################################################################"
#sudo apt-get install -y expat libexpat1-dev
#sudo apt-get install -y libcppunit-1.12-1 libcppunit-dev
#sudo apt-get install -y libtool libcurl4-gnutls-dev
#sudo apt-get install -y swig
#mkdir -p $SRCDIR/libkml
#cd $SRCDIR/libkml
#wget $LIBKML_SRC_URL
#tar xvvf $LIBKML_SRC
#cd libkml-$LIBKML_VER
#./configure --prefix=$LIBKML_PATH --disable-java  >& log_libkml_configure.out
#make >& log_libkml_make.out
#make install >& log_libkml_make_install.out
#sh -c "echo $LIBKML_PATH/lib/python2.6/site-packages > /usr/local/lib/python2.6/dist-packages/libkml.pth"
# QUICK TEST: Open up a python shell.  Type 'import kmldom'

#echo "###################################################################"
#echo "Downloading and installing pylibkml..."
#echo "###################################################################"
#hg clone https://pylibkml.googlecode.com/hg/ /usr/local/pylibkml
#sh -c "echo /usr/local/pylibkml/src > /usr/local/lib/python2.6/dist-packages/pylibkml.pth"
# QUICK TEST: Open up a python shell.  Type 'import pylibkml'

echo "###################################################################"
echo "Create a PostgreSQL Database Superuser"
echo "###################################################################"
sudo su -c "createuser --login --inherit --superuser --createdb --createrole --pwprompt" - postgres

# change the postgresql authentication to require a md5 password
sudo sed -i 's|local\s*all\s*all\s*ident sameuser$|local all all md5|g' /etc/postgresql/$POSTGRESQL_VER/main/pg_hba.conf
# restart PostgreSQL so that authentication rules are changed
sudo /etc/init.d/postgresql-$POSTGRESQL_VER restart

echo "###################################################################"
echo "Installing Django OLWidget"
echo "###################################################################"

sudo easy_install django-olwidget

echo "###################################################################"
echo "Installing HDF5..."
echo "###################################################################"

mkdir -p $HDF5_PATH
cd $HDF5_PATH
HDF5_TAR=hdf5-$HDF5_VER.tar.gz
wget http://www.hdfgroup.org/ftp/HDF5/current/src/$HDF5_TAR
tar -xzvf $HDF5_TAR
cd hdf5-$HDF5_VER
./configure --prefix=$HDF5_PATH --enable-shared --enable-hl >& log_hdf5_configure.log
make >& log_hdf5_make.log 
make install >& log_hdf5_make_install.log 
sh -c "echo $HDF5_PATH'/lib' > /etc/ld.so.conf.d/hdf.conf" 
ldconfig

echo "###################################################################"
echo "Installing netCDF4..."
echo "###################################################################"

mkdir -p $NETCDF4_PATH
cd $NETCDF4_PATH
NETCDF4_TAR=netcdf-$NETCDF4_VER.tar.gz
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/$NETCDF4_TAR
tar -xzvf $NETCDF4_TAR
cd netcdf-$NETCDF4_VER
./configure --enable-netcdf-4 --with-hdf5=$HDF5_PATH --enable-shared --prefix=$NETCDF4_PATH >& log_netcdf_configure.log 
make >& log_netcdf_make.log 
make install >& log_netcdf_make_install.log 
sh -c "echo $NETCDF4_PATH'/lib' > /etc/ld.so.conf.d/netcdf.conf" 
ldconfig

echo "###################################################################"
echo "Installing netcdf4-python..."
echo "###################################################################"

mkdir -p $NETCDF4_PYTHON_PATH
cd $NETCDF4_PYTHON_PATH
NETCDF4_PYTHON_TAR=netCDF4-$NETCDF4_PYTHON_VER.tar.gz
wget http://netcdf4-python.googlecode.com/files/$NETCDF4_PYTHON_TAR
tar -xzvf $NETCDF4_PYTHON_TAR
cd netCDF4-$NETCDF4_PYTHON_VER
export HDF5_DIR=$HDF5_PATH
export NETCDF4_DIR=$NETCDF4_PATH
python setup.py install 
cd test 
python run_all.py

echo "finished at:"; date
echo "Done."

