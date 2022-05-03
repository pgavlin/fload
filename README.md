# fload: A FAT32 Bootloader for RC2014 Systems

`fload` is a simple FAT32 bootloader for RC2014 systems with a CF card interface, pageable
ROM, 64K of RAM, and SIO/2 serial interface. It is compatible with the CP/M boot ROM and the
Small Computer Monitor CP/M loader. The bootloader requires a CF card with an MBR partition
table and two partitions: one for the bootloader itself, and one for boot configuration and
user programs.

The first partition must begin at LBA 1 and end at LBA 23 in order to be compatible with the
CP/M loader, which reads the first 24 sectors of the card at D000 before jumping to the address
found at FFFE (the last word of the last loaded sector). The bootloader itself requires the
last kilobyte of memory. The largest image the loader can boot is therefore a 63KB image loaded
at 0000. The bootloader will refuse to load an image that will not fit in the space between
the load address and the beginning of its reserved space.

The second partition must be formatted using FAT32, but is otherwise unrestricted.

The setup instructions below are targeted at macOS users.

## boot.cfg

Once the card has been configured for operation with `fload`, the image to boot can be changed
by editing `boot.cfg` on the card's data partition. `boot.cfg` must contain a single line of
the form `[load address]:[start address]:[program filename]`. Both the load and start address
must be four-digit hex numbers. The program filename must not be more than 31 characters long.

## Setup

### Build Requirements

The host system must have [`sdcc`](http://sdcc.sourceforge.net) and [Go](https://go.dev) installed in order to build this project.

### Creating an empty disk image (optional)

NOTE: this step is optional, but is useful for creating disk images for distribution or for
use with emulators.

```console
$ dd if=/dev/zero of=cf128.img iflag=fullblock bs=1M count=128
$ hdiutil attach -nomount -blocksize 512 cf128.img
/dev/diskN
```

### Formatting the CF card or disk image

```console
$ fdisk -e /dev/diskN
The signature for this MBR is invalid.
Would you like to initialize the partition table? [y] y
Enter 'help' for information
fdisk:*1> edit 1
         Starting       Ending
 #: id  cyl  hd sec -  cyl  hd sec [     start -       size]
------------------------------------------------------------------------
 1: 00    0   0   0 -    0   0   0 [         0 -          0] unused      
Partition id ('0' to disable)  [0 - FF]: [0] (? for help) CF
Do you wish to edit in CHS mode? [n] n
Partition offset [0 - 262144]: [63] 1
Partition size [1 - 262143]: [262143] 23
fdisk:*1> edit 2
         Starting       Ending
 #: id  cyl  hd sec -  cyl  hd sec [     start -       size]
------------------------------------------------------------------------
 2: 00    0   0   0 -    0   0   0 [         0 -          0] unused      
Partition id ('0' to disable)  [0 - FF]: [0] (? for help) 0B
Do you wish to edit in CHS mode? [n] 
Partition offset [0 - 262144]: [24] 
Partition size [1 - 262120]: [262120] 
fdisk:*1> write
Writing MBR at offset 0.
fdisk: 1> quit
$ diskutil eraseVolume FAT32 RC2014 /dev/diskNs2
```

### Building and installing the bootloader and example program

```console
$ cd tools
$ go build ./cmd/ihex2bin
$ cd ../src
$ make
...
$ dd if=fload.bin of=/dev/diskNs1 bs=512
23+0 records in
23+0 records out
11776 bytes transferred in 0.004754 secs (2477072 bytes/sec)
$ cd ../example
$ make
$ cp hello.bin /Volumes/RC2014
$ echo "9000:9000:hello.bin" >/Volumes/RC2014/boot.cfg
$ hdiutil eject /dev/diskN
```

### Running

Insert the CF card into an appropriately-configured RC2014 system and boot. The system should
display output similar to the example below on SIOA. The example uses SCM with the CP/M loader
extension to start the bootloader.

```console
Small Computer Monitor - RC2014
*CPM
fload FAT32 bootloader v0.10
loading hello.bin at 9000...
booting from 9000
Hello, world!
```

## Implementation Details

In order to allow larger images to be loaded, the bootloader operates in two phases. First, the
loader uses the Petit FatFs library to mount the filesystem, read its configuration from boot.cfg,
and locate the image to load. Although it would be possible to use the FatFs library to read the
contents of the image, this comes at the cost of retaining the FatFs code in memory. This cost is
substantial: the FatFs library occupies the bulk of the nearly 6KB of code used by the first phase.
Instead of paying this cost, the last step of the first phase reads out the starting LBAs of each
cluster in the image to load and stores them in an array. The second phase, which occupies the top
kilobyte of RAM, then loads the data from each cluster in turn directly into the load space.

It would likely be possible to save additional space by reimplementing the FAT traversal code in
assmebly for use by the second phase and terminating the first phase once the LBA of the starting
cluster of the image to load has been located.

## Future work

- It might be nice if the bootloader supported loading Intel HEX files.

## Acknowledgements

Many thanks to ChaN for [Petit FatFs](http://elm-chan.org/fsw/ff/00index_p.html), which the bootloader uses to interface with the FAT32 filesystem.
