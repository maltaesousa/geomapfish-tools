# Getting Started with GeoMapFish - **TL; DR**

Open a linux console, and execute the following commands:
```
wget https://raw.githubusercontent.com/remyguillaume/geomapfish-tools/
main/install.sh
chmod +x install.sh
./install.sh
```

Then, follow the instructions.  

Your application is at https://localhost:8484.  
The admin interface is at https://localhost:8484/admin.  
The default credentials are admin/admin.

That's it!  
Enjoy :-)

___
___

# Getting Started with GeoMapFish - **Long version**

## Introduction

This page goes through the basic, required steps to create your first GeoMapFish application from scratch. It is based on **Version 2.5**. To learn what GeoMapFish is all about, please visit our [homepage](https://geomapfish.org/).

This guide is written for Linux systems. GeoMpaFish works on Windows systems as well, but as the community is using Linux in a large majority, there is no guide for Windows at the moment.

## Step 1: Configure proxies

If you are behind a corporate proxy, you will have to configure the proxies. This can be done like this:

```
export http_proxy=http://user:password@proxy_host:proxy_port
export https_proxy=http://user:password@proxy_host:proxy_port
export no_proxy=localhost,127.0.0.1,mydomain.ch
```

## Step 2: Install requirements

The first step is to install the GeoMapFish requirements.  
You will need to have the following components installed on your system:

- Git
- Python >= 3.5
- Docker >= 17.05
- Docker-Compose

You can install the requirements by using your package manager.  
For example, on Debian, you can do the following:

```
apt update && apt install -y git python3 docker docker-compose
```

In order to be able to use GeoMapFish, your linux user mut be part of the docker group:

```
usermod -aG docker myuser
```

## Step 3: Prepare database

To store its configuration, GeoMapFish is using a PostgreSQL database with the following required extensions:

- PostgreSQL >= 9.1
- PostGIS >= 2.1
- hstore
- pg_trgm

**If you don't have any Postgres database yet, the installation script can download and configure one for you. If this is what you want, you can jump directly to Step 4**.

Otherwise, if you want to use you own database, the installation script will help you to configure GeoMapFish in order to use it, but you will have to execute first some commands on the database manually.

### 1. Create database:
```
CREATE DATABASE mydb;
```

### 2. Activate extensions:
```
CREATE EXTENSION postgis;
CREATE EXTENSION hstore;
CREATE EXTENSION pg_trgm;
```

### 3. Create User, Schema, and configure rights:
```
CREATE USER www PASSWORD 'secret';
CREATE SCHEMA main;
CREATE SCHEMA main_static;
GRANT ALL ON SCHEMA main TO www;
GRANT ALL ON SCHEMA main_static TO www;
```

## Step 4: Install GeoMapFish

You are now ready to install GeoMapFish.  
Let's do it!

First of all, download the installation script:
```
wget https://raw.githubusercontent.com/remyguillaume/geomapfish-tools/
main/install.sh
```

Make it executable:
```
chmod +x install.sh
```

The installation script will guide you through the configuration process.  
Just start it, and follow the instructions:
```
./install.sh
```

The questions asked by the installation script should be self-explanatory.  
If there's something you don't understand, please feel free to ask for help at contact@geomapfish.org.

## Step 5: First start

You should now have a working instance of GeoMapFish.  
Congratulations!

Now, it's time to start your application for the first time. You should be able to do this at https://hostname:port (for exemple https://localhost:8484).

Because your new instance of GeoMapFish doesn't have any valid SSL certificat yet, you will very likely get a warning from your Browser:
```
NET::ERR_CERT_AUTHORITY_INVALID
```

For the moment, just ignore it and proceed to website anyway.  
You will be able to see the application:

![First start](img/first_start.png)

## Step 6: Login

On the right side of the application, you will see a toolbar.  
At the very top of this toolbar, you can login to your application.

The default credentials are:
- Username : **admin**
- Password : **admin**

![Admin Login](img/admin_login.png)

Once logged in, you will have to change the admin password:

![Change Password](img/change_pass.png)

Ok, there you are !

![Admin connected](img/admin_connected.png)

Well... it's quite empty for now.  
Let's add some data!

## Step 7: Add some basemap

If you want a nice mapping application, I guess you need a background map to get started.  
Let's add one.

