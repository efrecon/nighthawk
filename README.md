# NETGEAR NightHawk Router reboot

This implements a single command, e.g. `reboot`, which is able to restart
NightHawk routers from NETGEAR (tested on [R6400] and [R7000]).

## Usage

### `reboot`

```shell
./nighthawk.sh -p SeCRet reboot http://192.168.0.1
```

### `help`

To get some help, either call the script with the `-h` command-line option, or
the `help` command.

  [R6400]: https://www.netgear.com/home/wifi/routers/r6400/
  [R7000]: https://www.netgear.com/home/wifi/routers/r7000/
