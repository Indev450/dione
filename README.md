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

`SRB2KART_PROTO` is optional, and defaults to `srb2kart-16p` (which is vanilla kart server)

Other currently supported options are: `saturn-32p` (not compatible with vanilla mostly only because of 2 bytes for player skin field),
`saturn-126p` (not vanilla compatible because 126 is more than `MSCOMPAT_MAXPLAYERS`, which is 32)
