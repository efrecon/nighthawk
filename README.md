# NETGEAR NightHawk Router reboot

This implements a single command, e.g. `reboot`, which is able to restart
NightHawk routers from NETGEAR (tested on [R6400] and [R7000]).

## Usage

### `reboot`

Directly using the script, provided you have `curl` (well-tested) or `wget`
installed:

```shell
./nighthawk.sh -p SeCRet reboot http://192.168.0.1
```

A Docker image for this project is automatically built and published to the
GitHub Container Registry for every change on the `main` branch. So, provided
you have Docker installed and that you are able to create and run containers
from your account, the following command should achieve the same as the previous
command:

```shell
docker run -it --rm ghcr.io/efrecon/nighthawk -p SeCRet reboot http://192.168.0.1
```

### `help`

To get some help, either call the script with the `-h` command-line option, or
the `help` command.

  [R6400]: https://www.netgear.com/home/wifi/routers/r6400/
  [R7000]: https://www.netgear.com/home/wifi/routers/r7000/
