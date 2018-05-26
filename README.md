# repo

My custom apt repo.

To install software from this repo:

    $ sudo apt-get install apt-transport-https -y
    $ echo 'deb https://thusoy-apt.s3-accelerate.amazonaws.com/apt/debian (jessie|stretch) main' | sudo tee -a /etc/apt/sources.list
    $ curl https://raw.githubusercontent.com/thusoy/repo/master/release-key.asc | sudo apt-key add -
    $ sudo apt-get update
    $ sudo apt-get install <package>

Each package is built from the spec in this repo.


## Motivation

Learn apt packaging.
Make it easy to build a documented, automated and secure private repo.
Preferably everything should be reproducible.
