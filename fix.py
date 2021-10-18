#!/usr/bin/python

import re, sys, socket, struct

# Convert 32-bit big-endian value in first match group to dotted-quad string
# and 64-bit little-endian value in second match group to ASN:VPN-ID format.
def fix(match):
    ip = match.group(1)
    ip = socket.inet_ntoa(struct.pack('=L', int(ip))) if ip.isdigit() else ip
    id_ = int(match.group(2))
    asn = id_ >> 32 & 0xffff
    id_ = '%d:%d' % (asn, id_ & 0xffffffff) if asn else str(id_ & 0xffffffff)
    return 'PW neighbor: %s, ID: %s' % (ip, id_)

# Read lines from stdin, fix the values and write to stdout
for line in iter(sys.stdin.readline, ''):
    try:
        print re.sub('PW neighbor: (\S+), ID: (\d+)', fix, line.rstrip())
    except IOError:
        sys.exit(1)
