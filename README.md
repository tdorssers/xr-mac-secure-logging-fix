# IOS XR MAC secure logging fix

Considering these MAC secure logging messages:

| Version | Message |
| --- | --- |
| cXR 6.0.2 | LC/0/1/CPU0:Oct 10 10:20:07.476 CEST: l2fib[252]: %L2-L2FIB-5-SECURITY_MAC_SECURE_VIOLATION_PW : MAC secure in PW neighbor: 10.254.255.6, ID: 3801 detected violated packet that was previously learned in PW neighbor: 10.254.255.5, ID: **2973169635823321**- source MAC: 00cc.fcc2.3e32, destination MAC: 0100.0ccc.cccd; action: none |
| cXR 6.4.2 | LC/0/0/CPU0:Oct 11 06:18:01.365 CEST: l2fib[252]: %L2-L2FIB-5-SECURITY_MAC_SECURE_VIOLATION_PW : MAC secure in PW neighbor: 10.254.255.5, ID: 128 detected violated packet that was previously learned in PW neighbor: 10.254.255.11, ID: **2973169635819648**- source MAC: 0000.0c9f.f090, destination MAC: ffff.ffff.ffff; action: none |
| cXR 6.7.3 | LC/0/0/CPU0:Oct 13 08:33:45.957 CEST: l2fib[253]: %L2-L2FIB-5-SECURITY_MAC_SECURE_VIOLATION_PW : MAC secure in PW neighbor: **184483587**, ID: 666 detected violated packet that was previously learned in PW neighbor: **184483585**, ID: **2973169635820186**- source MAC: 7001.b5f1.257c, destination MAC: ffff.ffff.ffff; action: none |
| eXR 7.1.3 | LC/0/1/CPU0:Oct 11 06:18:01.367 CEST: l2fib[213]: %L2-L2FIB-5-SECURITY_MAC_SECURE_VIOLATION_PW : MAC secure in PW neighbor: **100662794**, ID: **2973169635819648** detected violated packet that was previously learned in PW neighbor: **201326090**, ID: **2973169635819648**- source MAC: 0000.0c9f.f090, destination MAC: ffff.ffff.ffff; action: none |

Two issues can be identified:
* The PW ID is not formatted as ASN:VPN-ID when VPLS with BGP Autodiscovery is used
* The neighbor IP is always not formatted as a dotted-quad string

BGP Autodiscovery uses a VPLS ID, which by default equals to ASN:VPN ID. The VPN ID is 4 bytes in size, and if a 4 byte ASN is used, the lower two bytes of the ASN are used to build the VPLS ID.

This fix uses the CLI capability to utilize a script for post processing.

## Classic XR

The second PW ID is not formatted as ASN:VPN-ID when BGP AD is used, making the PW ID unreadable. Newer cXR versions do not format the neighbor IP as dotted-quad string, but as a *little-endian* unsigned long, making the neighbor IP unreadable.
IOS XR comes with Tool Command Language 8.3.2. The Tcl script reads lines from stdin and formats the neighbor IP and PW ID properly (if needed) and writes the lines to stdout. Floating point arithmetic is used because Tcl 8.3 does not support 64-bit integers.

Create a file with execute permissions:

`show clock | file fix.tcl`

Copy the Tcl script to the router overwriting the file just created:

`scp fix.tcl tim@10.23.62.4:/disk0a:/usr/`

The absolute path needs to be specified to use the script:

`show logging | include l2fib | utility script /disk0a:/usr/fix.tcl`

The script deciphered the cXR 6.7.3 log message shown above:

LC/0/0/CPU0:Oct 13 08:33:45.957 CEST: l2fib[253]: %L2-L2FIB-5-SECURITY_MAC_SECURE_VIOLATION_PW : MAC secure in PW neighbor: **10.254.255.3**, ID: 666 detected violated packet that was previously learned in PW neighbor: **10.254.255.1**, ID: **36885:666**- source MAC: 7001.b5f1.257c, destination MAC: ffff.ffff.ffff; action: none

## 64-bit XR

Both PW IDs are not formatted as ASN:VPN-ID when BGP AD is used. Newer eXR versions do not format the neighbor IP as dotted-quad string, but as a *big-endian* unsigned long. Except for the MAC addresses, the log message is unreadable.
Python 2.7.3 is part of the 64-bit XR software. The Python script reads lines from stdin and formats the neighbor IP and PW ID properly (if needed) and writes the lines to stdout.

Create a file with execute permissions:

`show clock | file fix.py`

Copy the Python script to the router overwriting the file just created:

`scp fix.py tim@10.23.62.2:/misc/scratch`

Use the fix as follows:

`show logging | include l2fib | utility script fix.py`

The script deciphered the eXR 7.1.3 log message shown above:

LC/0/1/CPU0:Oct 11 06:18:01.367 CEST: l2fib[213]: %L2-L2FIB-5-SECURITY_MAC_SECURE_VIOLATION_PW : MAC secure in PW neighbor: **10.254.255.5**, ID: **36885:128** detected violated packet that was previously learned in PW neighbor: **10.254.255.11**, ID: **36885:128**- source MAC: 0000.0c9f.f090, destination MAC: ffff.ffff.ffff; action: none
