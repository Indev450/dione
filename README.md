# SRB2Kart Dione - Discord bot

A Discord bot for displaying SRB2Kart server status, written using `luvit`

## Installing

Install luvit if you don't have it already (refer to https://luvit.io/install.html)

Clone repository:

```sh
git clone --recursive https://github.com/Indev450/dione
cd dione
```

Install dependencies:

```sh
lit install SinisterRectus/discordia
lit install Bilal2453/discordia-interactions
```

## Running

```sh
DISCORD_TOKEN=<your token> SRB2KART_ADDRESS=<ip:port of server> SRB2KART_PROTO=<protocol> luvit init.lua
```

## Environment variables

`DISCORD_TOKEN` - required, bot token

`SRB2KART_ADDRESS` - optional, address of srb2kart server, which would be asked for info (format is `host:port`. host defaults to `127.0.0.1`, port defaults to `5029`)

`SRB2KART_PROTO` - optional, and defaults to `srb2kart-16p` (which is vanilla kart server). Other currently supported options are:

- `saturn-32p` (not compatible with vanilla mostly only because of 2 bytes for player skin field),
- `saturn-126p` (not vanilla compatible because 126 is more than `MSCOMPAT_MAXPLAYERS`, which is 32)

`SRB2KART_GAMEMODEFILE` - optional, path to file which would be read to fetch server gamemodes. File should store each gamemode on new line. If this
variable is not found, /gamemode command will not be available
