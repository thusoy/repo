# repo

My custom apt repo.

To install software from this repo:

    $ sudo apt-get install apt-transport-https -y
    $ echo 'deb [signed-by=/usr/share/keyrings/thusoy-archive-keyring.gpg] https://repo.thusoy.com/apt/debian $(lsb_release -cs) main' | sudo tee -a /etc/apt/sources.list
    $ curl -o /usr/share/keyrings/thusoy-archive-keyring.gpg https://raw.githubusercontent.com/thusoy/repo/master/release-key.gpg
    $ sudo apt-get update
    $ sudo apt-get install <package>

Each package is built from the spec in this repo.


## Motivation

Learn apt packaging.
Make it easy to build a documented, automated and secure private repo.
Preferably everything should be reproducible.
