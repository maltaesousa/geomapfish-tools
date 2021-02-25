#!/bin/bash

Default=$'\e[0m'
Green=$'\e[1;32m'
Red=$'\e[1;31m'

gmf_port=8484

# Requirements
##############

check()
{
  if command -v $1 > /dev/null
  then
    version=`$1 --version 2>&1`
    echo "${Green}[OK]  $version"
  else
    echo "${Red}[NOK] $1 NOT FOUND"
    echo "Please install the missing requirement."
    echo "Aborting GeoMapFish installation..."
    exit
  fi
}

checkuser()
{
  user=`whoami`
  if getent group docker | grep -q $user
  then
    echo "${Green}[OK]  User $user is in group docker"
  else
    echo "${Red}[NOK] User $user is not in group docker"
    exit
  fi
}

checkport()
{
  used=`ss -tunlp | grep 'LISTEN' | grep $gmf_port | wc -l`
  while [ used == 1 ]; do
    $gmf_port=$gmf_port+1
    if [ $gmf_port > 8500 ]
    then
      echo "${Red}[NOK] Cannot find any free port between 8484 and 8500 to start GMF."
      exit
    fi
    used=`ss -tunlp | grep 'LISTEN' | grep $gmf_port | wc -l`
  done
  echo "${Green}[OK]  Port $gmf_port will be used by GeoMapFish"
}

echo
echo "${Default}---------------------------------------------------------------------------"
echo "${Default}Analysing requirements..."
check 'git'
check 'docker'
check 'docker-compose'
check 'python3'
check 'ss'
checkuser
checkport

# Proxy configuration
#####################

proxy()
{
  if [ -z ${!1} ]
  then 
    echo "${Green}$1: <not set>"
  else
    echo "${Green}$1: set to ${!1}"
  fi
}

echo
echo "${Default}--------------------------------------------------------------------------"
echo "${Default}If you are behind a proxy, the environment variables should be configured."
echo "Please verify that the following configuration is correct:"
proxy 'http_proxy'
proxy 'https_proxy'
proxy 'no_proxy'

read -p "${Default}Do you want to continue with this configuration? [y/n] " -n 1 -r cont
echo
if ! [[ $cont =~ ^[Yy]$ ]]
then
  echo "${Red}Aborting GeoMapFish installation..."
  exit
fi
 
# GeoMapFish configuration
##########################

echo
echo "${Default}--------------------------------------------------------------------------"
echo "Ok, let's configure GeoMapFish before we can install it:"
read -p "What version do you want to install? [2.5] " -r gmfver
gmfver=${gmfver:-2.5}
read -p "What is the fantastic name of your project? [my-super-gmf-app] " -r projname
projname=${projname:-my-super-gmf-app}
read -p "What coordinate system do you want to use? [2056] " -r srid
srid=${srid:-2056}
read -p "What extent do you want to use? [2420000,1030000,2900000,1350000] " -r extent
extent=${extent:-2420000,1030000,2900000,1350000}

# Git configuration
while [ -z $gitmail ]
do
  read -p "What email do you want to use for git? " -r gitmail
done
while [ -z "$gitname" ]
do
  read -p "What name do you want to use for git? " -r gitname
done

echo "${Green}Version to install: $gmfver"
echo "${Green}Project name      : $projname"
echo "${Green}Coordinate system : $srid"
echo "${Green}Extent            : $extent"
echo "${Green}Project Directory : $projname"
echo "${Green}Git Email         : $gitmail"
echo "${Green}Git Name          : $gitname"

echo "${Default}Please verify the configuration."
read -p "${Default}Do you want to start the installation? [y/n] " -n 1 -r cont
echo
if ! [[ $cont =~ ^[Yy]$ ]]
then
  echo "${Red}Aborting GeoMapFish installation..."
  exit
fi

# Start installation
####################

echo
echo "${Default}---------------------------------------------------------------------------"
echo "${Default}Downloading containers..."
docker pull camptocamp/geomapfish-tools:$gmfver
docker pull camptocamp/geomapfish:$gmfver
echo "${Green}OK."

echo
echo "${Default}---------------------------------------------------------------------------"

# Create project
echo "${Default}Creating GeoMapFish project..."
docker run --rm -ti --volume=$(pwd):/src --env=SRID=$srid --env=EXTENT="$extent" camptocamp/geomapfish-tools:$gmfver run $(id -u) $(id -g) /src pcreate -s c2cgeoportal_create $projname > install.log
echo "${Green}OK."

# Update project
echo "${Default}Updating project..."
docker run --rm -ti --volume=$(pwd):/src --env=SRID=$srid --env=EXTENT="$extent" camptocamp/geomapfish-tools:$gmfver run $(id -u) $(id -g) /src pcreate -s c2cgeoportal_update $projname >> install.log
echo "${Green}OK."

# Correct error in .eslintrc file
echo "${Default}Gathering positiveness..."
cd $projname
sed -i 's/code: 110/code: 200/g' geoportal/.eslintrc
echo "${Green}PERFECT!"

# Database configuration
########################

echo
echo "${Default}---------------------------------------------------------------------------"
echo "The first step is done. Now, we'll have to configure the database."
echo "If you want, a test database can be installed locally automatically."
echo "But if you already have configured one, it can be used."

read -p "Do you want to download and configure a database automatically? [y/n] " -n 1 -r cont
echo
if [[ $cont =~ ^[Yy]$ ]]
then
  echo "Configuring GeoMapFish Database..."
  
  dbhost=172.17.0.1
  dbport=5432
  dbname=mydb
  dbuser=www
  dbpass=secret
  
  docker pull postgis/postgis:11-3.1
  docker kill gmf_postgis >> ../install.log
  docker run --rm --name gmf_postgis -p 5432:5432 -v postgres:/var/lib/postgresql/data -e POSTGRES_PASSWORD=secret -d postgis/postgis:11-3.1 >> ../install.log
  # Wait the postgres startup
  sleep 20
  docker exec gmf_postgis bash -c "psql -U postgres -c 'CREATE DATABASE mydb;'" >> ../install.log
  docker exec gmf_postgis bash -c "psql -U postgres -d mydb -c 'CREATE EXTENSION postgis;'" >> ../install.log
  docker exec gmf_postgis bash -c "psql -U postgres -d mydb -c 'CREATE EXTENSION hstore;'" >> ../install.log
  docker exec gmf_postgis bash -c "psql -U postgres -d mydb -c \"CREATE USER www PASSWORD 'secret';\"" >> ../install.log
  docker exec gmf_postgis bash -c "psql -U postgres -d mydb -c 'CREATE SCHEMA main;'" >> ../install.log
  docker exec gmf_postgis bash -c "psql -U postgres -d mydb -c 'CREATE SCHEMA main_static;'" >> ../install.log
  docker exec gmf_postgis bash -c "psql -U postgres -d mydb -c 'GRANT ALL ON SCHEMA main TO www;'" >> ../install.log
  docker exec gmf_postgis bash -c "psql -U postgres -d mydb -c 'GRANT ALL ON SCHEMA main_static TO www;'" >> ../install.log
  echo "${Green}OK." 
else
  echo "${Default}Ok, let's configure your database connection then.."
  while [ -z $dbhost ]
  do
    read -p "Database Host: " -r dbhost
  done
  while [ -z $dbport ]
  do
    read -p "Database Port: " -r dbport
  done
  while [ -z $dbname ]
  do
    read -p "Database Name: " -r dbname
  done
  while [ -z $dbuser ]
  do
    read -p "Database User: " -r dbuser
  done
  while [ -z $dbpass ]
  do
    read -p "Database Password: " -r dbpass
  done
  
  echo "${Default}Please verify the configuration."
  echo "${Green}Database Host    : $dbhost"
  echo "${Green}Database Port    : $dbport"
  echo "${Green}Database Name    : $dbname"
  echo "${Green}Database User    : $dbuser"
  echo "${Green}Database Password: $dbpass"

  read -p "${Default}Do you want to continue? [y/n] " -n 1 -r cont
  echo
  if ! [[ $cont =~ ^[Yy]$ ]]
  then
    echo "${Red}Aborting GeoMapFish installation..."
    exit
  fi

fi

# Env configuration
###################

echo
echo "${Default}---------------------------------------------------------------------------"
echo "Configuring GeoMapFish project..."
sed -i "s/PGDATABASE=gmf_.*/PGDATABASE=${dbname}/g" env.project
sed -i "s/PGHOST=pg-gs.camptocamp.com/PGHOST=${dbhost}/g" env.project
sed -i "s/PGHOST_SLAVE=pg-gs.camptocamp.com/PGHOST_SLAVE=${dbhost}/g" env.project
sed -i "s/PGPORT=30100/PGPORT=${dbport}/g" env.project
sed -i "s/PGPORT_SLAVE=30101/PGPORT_SLAVE=${dbport}/g" env.project
sed -i "s/PGUSER=<user>/PGUSER=${dbuser}/g" env.project
sed -i "s/PGPASSWORD=<pass>/PGPASSWORD=${dbpass}/g" env.project
sed -i "s/PGSSLMODE=require/PGSSLMODE=prefer/g" env.project
echo "${Green}OK."

# Initialize git and firt commit
echo "${Default}Committing first version..."
git init . >> ../install.log
git add . >> ../install.log
git config user.email "$gitmail" >> ../install.log
git config user.name "$gitname" >> ../install.log
git commit -m "First commit" >> ../install.log
echo "${Green}OK."

# Build the app
###############
echo "${Default}Compiling GeoMapFish project..."
./build >> ../install.log
echo "${Green}OK."


# Start the app
###############
echo "${Default}Starting GeoMapFish..."
docker-compose up -d
echo "${Green}OK."

# Create schemas
################
echo "${Default}Initializing Database..."
docker-compose exec geoportal alembic --name=main upgrade head
docker-compose exec geoportal alembic --name=static upgrade head
echo "${Green}OK."

echo
echo "${Default}---------------------------------------------------------------------------"
echo "${Green}DONE!"
echo "${Default}The application can be accessed at https://localhost:$gmf_port"
echo "The next things to do:"
echo "- Connect to the application with admin/admin and change the password."
echo "- Go at https://localhost:$gmf_port/admin and add your own data."
echo "- Enjoy !"


