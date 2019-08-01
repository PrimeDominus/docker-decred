This is the the [Docker image](https://hub.docker.com/r/jpbriquet/decred/) for [Decred cryptocurrency releases](https://github.com/decred/decred-binaries/releases).

# What is Decred?

<img src="https://raw.githubusercontent.com/decred/dcrweb/master/www-root/content/images/256.png" alt="Logo" width="200px;"/>

Decred is an open and progressive cryptocurrency with a system of community-based governance integrated into its blockchain. The fusion of technology, community, and governance the Decred way means development is self-funding and remains sustainable.

> Website: [www.decred.org](https://www.decred.org)

> Documentation : [docs.decred.org](https://docs.decred.org)


# Image Information

This Decred docker image is based on the Ubuntu image 18.04 LTS (Bionic Beaver) and
contains all binaries in decred releases:

- [Decred Daemon (chainserver) / dcrd](https://github.com/decred/dcrd)
- [Decred Wallet / dcrwallet](https://github.com/decred/dcrwallet)
- [Decred Controller (rpc client) / dcrctl](https://github.com/decred/dcrd/tree/master/cmd/dcrctl)


# Supported tags and respective `Dockerfile` links

#### Releases:

-	[`1.4.0, latest` (*1.4.0/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/1.4.0/Dockerfile)
-	[`1.3.0` (*1.3.0/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/1.3.0/Dockerfile)
-	[`1.2.0` (*1.2.0/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/1.2.0/Dockerfile)
-	[`1.1.2` (*1.1.2/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/1.1.2/Dockerfile)
-	[`1.1.0`, (*1.1.0/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/1.1.0/Dockerfile)
-	[`1.0.8`, (*1.0.8/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/1.0.8/Dockerfile)
-	[`1.0.7` (*1.0.7/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/1.0.7/Dockerfile)
-	[`1.0.5` (*1.0.5/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/1.0.5/Dockerfile)
-	[`1.0.3` (*1.0.3/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/1.0.3/Dockerfile)
-	[`1.0.1` (*1.0.1/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/1.0.1/Dockerfile)
-	[`0.8.2` (*0.8.2/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/0.8.2/Dockerfile)
-	[`0.7.0` (*0.7.0/Dockerfile*)](https://raw.githubusercontent.com/jpbriquet/docker-decred/0.7.0/Dockerfile)

[![](https://imagelayers.io/badge/jpbriquet/decred:latest.svg)](https://imagelayers.io/?images=jpbriquet/decred:latest)

Only official [Decred release binaries](https://github.com/decred/decred-release/releases) are used to build this image. These binaries are verified based on the recommended [binaries verification process](https://docs.decred.org/advanced/verifying-binaries/). (refer to Dockerfile content for details)


# How to use this image

This Decred Docker image can be used to create containers that can start each of the included executables (dcrd, dcrwallet, ...).

The image can be used as follow:
```console
$ docker run -it jpbriquet/decred:latest DECRED_COMMAND
```

e.g. :
```console
$ docker run -it jpbriquet/decred:latest dcrd
```


# Decred infrastructure based on Docker containers

This guide describes how to configure a Decred daemon (dcrd) container. The next step will be to connect a Decred wallet (dcrwallet) container on the daemon.
Both containers will be manageable with the Decred controller tool (dcrctl), which will give a way to unlock the Decred wallet, or get Decred network information from the Decred daemon.

As it is an advanced configuration, it is strongly recommended to be familiar with [Docker](https://www.docker.com) and with [Decred documentation](https://docs.decred.org/)

## Prerequisites

### Create Decred private docker network
Our Decred containers will communicate on their own Docker bridge network called decrednet, they will be isolated from other containers eventually running on the Docker engine.

```console
$ docker network create --driver bridge decrednet
```

### Create Docker data-volume containers
Docker volume will be used to store decred containers data that has to be persistent:
 * blockchain data
 * wallet data
 * ...

For more information about this Docker storage mode refer to  [Docker data-volume](https://docs.docker.com/engine/tutorials/dockervolumes).


#### Create a volume for the Decred daemon container:
```console
$ docker volume create --name dcrd-vol
```

#### Create a volume for the Decred wallet container:
```console
$ docker volume create --name dcrwallet-vol
```

### Configuration files

In this guide, configuration files are located outside of the containers and are in a "conf" directory. These configuration files will be available to our containers via a host file mount.

```console
`-- conf
    |-- dcrctl.conf
    |-- dcrd.conf
    |-- dcrwallet.conf
```

## Decred daemon container configuration (dcrd)

This chapter describe how to configure and start a Decred daemon container.
The Decred daemon container automatically connects to the Decred P2P network and then synchronize to the latest blockchain head block.
Later in this guide we will connect a wallet container to the daemon container.


### Prepare configuration file
Decred daemon can be started with command line arguments, however, this is not recommended for sensitive information like the RPC user/password.
It is possible to set this configuration in a dcrd.conf configuration file:

```console
; -------------------------------------------------------
; RPC server options - The following options control the built-in RPC server
; which is used to control and query information from a running dcrd process.
;
; NOTE: The RPC server is disabled by default if no rpcuser or rpcpass is
; specified.
; -------------------------------------------------------

rpclisten=0.0.0.0:9109
rpcuser=whatever_username_you_want
rpcpass=whatever_password_you_want
```

Adjust this configuration file to your needs, to view all options available, refer to the sample configuration of the [Decred daemon](https://github.com/decred/dcrd/blob/master/sample-dcrd.conf)

Save this configuration in the file dcrd.conf (in conf directory).


### Create container

The daemon container will use the data-volume  and the dcrd.conf configuration file created previously.

```console
$ docker run -d --name dcrd --net=decrednet -h dcrd -v dcrd-vol:/home/decred/.dcrd -v $PWD/conf/dcrd.conf:/home/decred/.dcrd/dcrd.conf jpbriquet/decred:latest dcrd
```

Once launched Decred daemon will read local blockchain data and then will synchronize with the p2p network. This step may take a while depending of the network connection speed.
Use docker logs to check what the container is doing.

```console
docker logs dcrd
15:39:18 2016-12-31 [INF] DCRD: Version 0.X.Y+release (Go version goA.B.C)
15:39:18 2016-12-31 [INF] DCRD: Home dir: /home/decred/.dcrd
15:39:18 2016-12-31 [INF] DCRD: Loading block database from '/home/decred/.dcrd/data/mainnet/blocks_ffldb'
15:39:18 2016-12-31 [INF] DCRD: Block database loaded
15:39:18 2016-12-31 [INF] INDX: Exists address index is enabled
15:39:18 2016-12-31 [INF] CHAN: Blockchain database version 2 loaded
...
```

The daemon container is now up and running.

### Stop/Start container

When the container has been created, standard Docker commands can be used.

#### Stop container
```console
docker stop dcrd
```

#### Start container
```console
docker start dcrd
```

### Dcrctl console for daemon container

The console can be connected on dcrd to get information about the blockchain.

```console
docker exec -it dcrd dcrctl getinfo

{
  "version": 1000100,
  "protocolversion": 2,
  "blocks": 94999,
  "timeoffset": 0,
  "connections": 7,
  "proxy": "",
  "difficulty": 802194.38990989,
  "testnet": false,
  "relayfee": 0.01,
  "errors": ""
}

```

## Decred wallet container (dcrwallet)

The Decred wallet container needs to connect on a Decred daemon container to have access to the blockchain and interact with the p2p network.

### Prepare configuration files
Decred wallet can be started with command line arguments, however, this is not recommended for sensitive information like the RPC user/password.
Prepare the dcrwallet.conf configuration file for the Decred wallet as follow:

```console
; -------------------------------------------------------
; RPC settings (both client and server)
; -------------------------------------------------------
username=whatever_wallet_username_you_want
password=whatever_wallet_password_you_want
dcrdusername=whatever_username_you_want
dcrdpassword=whatever_password_you_want


; ------------------------------------------------------------------------------
; RPC server settings
; ------------------------------------------------------------------------------

rpclisten=0.0.0.0:9110

; -------------------------------------------------------
; RPC client settings
; -------------------------------------------------------

; The server and port used for dcrd websocket connections.
rpcconnect=dcrd:9109

; File containing root certificates to authenticate a TLS connections with dcrd
cafile=~/.dcrd/rpc.cert
```

* dcrdusername and dcrdpassword are user and password to connect the wallet on the rpc service of the daemon, this variable must have the same value than in dcrd.conf.
* username and password are used to authenticate incoming connections on the rpc service of the wallet.

To view all options available, refer to the sample  [Decred wallet configuration](https://github.com/decred/dcrwallet/blob/master/sample-dcrwallet.conf)
Adjust it to your needs.

Save this configuration file as dcrwallet.conf in conf directory.


The Decred controller console (dcrctl) needs to know the RPC credentials to connect on the wallet.
Create following configuration file and save it as dcrctl.conf in conf directory.

```console
; ------------------------------------------------------------------------------
; RPC client settings
; ------------------------------------------------------------------------------

rpcuser=whatever_wallet_username_you_want
rpcpass=whatever_wallet_password_you_want
```



### Create or import wallet

The following command will launch the wallet creation assistant that can create a brand new wallet or import an existing wallet seed.

```console
$ docker run -it --rm -v dcrwallet-vol:/home/decred/.dcrwallet jpbriquet/decred:latest dcrwallet --create

Enter the private passphrase for your new wallet:
Confirm passphrase:
Do you want to add an additional layer of encryption for public data? (n/no/y/yes) [no]: no
Do you have an existing wallet seed you want to use? (n/no/y/yes) [no]:
Your wallet generation seed is:
...
Creating the wallet...
The wallet has been created successfully.
```

### Create container

The wallet container named 'dcrwallet' uses the wallet volume, the daemon volume (in read-only) and the dcrwallet.conf configuration file previously created.

This container is launched in interactive mode because the Decred wallet needs at first launch to know the wallet passphrase and you have to type it in the console.


```console
$ docker run -it --name dcrwallet --net=decrednet -h dcrwallet -v $PWD/conf/dcrwallet.conf:/home/decred/.dcrwallet/dcrwallet.conf -v $PWD/conf/dcrctl.conf:/home/decred/.dcrctl/dcrctl.conf -v dcrwallet-vol:/home/decred/.dcrwallet -v dcrd-vol:/home/decred/.dcrd:ro jpbriquet/decred:latest dcrwallet


16:23:52 2017-01-01 [INF] DCRW: Version 0.X.Y+release (Go version goA.B.C)
16:23:52 2017-01-01 [INF] DCRW: Generating TLS certificates...
16:23:53 2017-01-01 [INF] DCRW: Done generating TLS certificates
16:23:53 2017-01-01 [INF] DCRW: Attempting RPC client connection to dcrd:9109
16:23:53 2017-01-01 [INF] RPCS: Listening on 127.0.0.1:9110
16:23:53 2017-01-01 [INF] RPCS: Listening on [::1]:9110
16:23:53 2017-01-01 [INF] CHNS: Established connection to RPC server dcrd:9109
16:23:53 2017-01-01 [INF] WLLT: Opened wallet
*** ATTENTION ***
Since this is your first time running we need to sync accounts. Please enter
the private wallet passphrase. This will complete syncing of the wallet
accounts and then leave your wallet unlocked. You may relock wallet after by
calling 'walletlock' through the RPC.
*****************
Enter private passphrase:
16:24:00 2017-01-01 [INF] WLLT: The wallet has been unlocked without a time limit
16:24:00 2017-01-01 [INF] WLLT: Beginning a rescan of active addresses using the daemon. This may take a while.
16:24:03 2017-01-01 [INF] WLLT: The last used account was 0. Beginning a rescan for all active addresses in known accounts.
...
16:25:19 2017-01-01 [INF] WLLT: Blockchain sync completed, wallet ready for general usage.
...
```

Wait for the end of the synchronization, and then hit CTRL+C.

#### Proof-of-stake mining and ticket buy ####

You will need several additional options when launching the container, e.g. POS mining with the wallet (buying tickets and/or voting on tickets).

##### Vote on tickets automatically
Use option --enablevoting when you start the container

Example to start the wallet with automatic voting:
```console
$ docker run -it --name dcrwallet --net=decrednet -h dcrwallet -v $PWD/conf/dcrwallet.conf:/home/decred/.dcrwallet/dcrwallet.conf -v $PWD/conf/dcrctl.conf:/home/decred/.dcrctl/dcrctl.conf -v dcrwallet-vol:/home/decred/.dcrwallet -v dcrd-vol:/home/decred/.dcrd:ro jpbriquet/decred:latest dcrwallet --enablevoting
```

##### Buy tickets automatically
Consult the dcrwallet documentation and choose options related to the automatic ticket buyer.
Options starts with "--ticketbuyer." (e.g. --ticketbuyer.maxpriceabsolute=60, ...).
Add these options when you start the container.

Note: It is also possible to add these options in the dcrwallet.conf configuration file.


### Stop/Start container

When the container has been created, standard Docker commands can be used.

#### Stop container
```console
docker stop dcrwallet
```

#### Start container
```console
docker start dcrwallet
```

### Dcrctl console for wallet container

The console can be connected on the dcrwallet to do wallet related operations.
For instance unlocking the wallet or creating new transactions.

#### Unlock wallet for 60 minutes

Wallet has to be unlocked to send DCR tokens, to buy tickets, or to do solo POS mining.
Adjust the unlock duration as needed. (60 minutes in the example below, set it at 0 for unlimited unlocking)

```console
docker exec -it dcrwallet bash -c 'promptsecret | dcrctl --wallet walletpassphrase - 60'
```

#### Get stake Information

Get current stake information, difficulty (cost of the ticket), number of owned tickets, number of voted tickets...

```console
docker exec -it dcrwallet dcrctl --wallet getstakeinfo

{
  "blockheight": 95000,
  "poolsize": 41672,
  "difficulty": 56.49212635,
  "allmempooltix": 0,
  "ownmempooltix": 0,
  "immature": 0,
  "live": 0,
  "proportionlive": 0,
  "voted": 0,
  "totalsubsidy": 0,
  "missed": 0,
  "proportionmissed": 0,
  "revoked": 0,
  "expired": 0
}

```

#### Display vote choices

Display current proposals "agendaid", and for each the chosen choice "choiceid" (abstain, yes or no).

```console
docker exec -it dcrwallet dcrctl --wallet getvotechoices

{
  "version": 4,
  "choices": [
    {
      "agendaid": "sdiffalgorithm",
      "agendadescription": "Change stake difficulty algorithm as defined in DCP0001",
      "choiceid": "abstain",
      "choicedescription": "abstain voting for change"
    },
    {
      "agendaid": "lnsupport",
      "agendadescription": "Request developers begin work on Lightning Network (LN) integration",
      "choiceid": "abstain",
      "choicedescription": "abstain from voting"
    }
  ]
}
```

#### Set vote choice

Use the previous display vote choices command, and for each "agendaid" use following command to set your vote choice.
Example below is for the agendaid "sdiffalgorithm", replace it as needed.

* Vote yes:
```console
docker exec -it dcrwallet dcrctl --wallet setvotechoice sdiffalgorithm yes
```
* Vote no:
```console
docker exec -it dcrwallet dcrctl --wallet setvotechoice sdiffalgorithm no
```

* Abstain:
```console
docker exec -it dcrwallet dcrctl --wallet setvotechoice sdiffalgorithm abstain
```

Finally, display again your vote choices to check if "choiceid" field is correct.

# Upgrading from previous image version

* Get new image version
```console
docker pull jpbriquet/decred:latest
```

* Stop containers
```console
docker stop dcrwallet
docker stop dcrd
```

* Rename previous containers for backup

```console
docker rename dcrd dcrd_v0.8
docker rename dcrwallet dcrwallet_v0.8
```

* Start new dcrd an dcrwallet

Start containers, adjust command line as needed.

```console
docker run ... jpbriquet/dcrd:latest ...
docker run ... jpbriquet/dcrwallet:latest ...
```


# License

View [license information](https://github.com/decred/dcrwallet/blob/master/LICENSE) for the software contained in this image.

# Supported Docker versions

This image is officially supported on Docker version 1.13.x and above.

Support for older versions (down to 1.6) is provided on a best-effort basis.

Please see [the Docker installation documentation](https://docs.docker.com/installation/) for details on how to upgrade your Docker daemon.

# User Feedback

## Issues

If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/jpbriquet/docker-decred/issues).

If you have any problems with or questions about Decred tools and utilies provided in this image, please contact Decred Developer team on [GitHub](https://github.com/decred).

## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub issue](https://github.com/jpbriquet/docker-decred/issues), especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.
