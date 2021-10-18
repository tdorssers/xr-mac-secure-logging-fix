#!/pkg/sbin/tclsh

# Read lines from stdin, fix the values and write to stdout
while {[gets stdin line] >= 0} {
    set matchData [regexp -all -inline {PW neighbor: (\S+), ID: (\d+)} $line]
    foreach {match ip id} $matchData {
        # Convert 32-bit little-endian value to dotted-quad string format
        if {[string is integer $ip]} {
            set ip [format %d.%d.%d.%d \
                [expr {($ip >> 24) & 0xff}] [expr {($ip >> 16) & 0xff}] \
                [expr {($ip >> 8) & 0xff}] [expr {$ip & 0xff}]]
        }
        # Convert to 48-bit ASN:VPN-ID format using floating point math
        append id "."
        set upper [expr {int($id / (1 << 24))}]
        set lower [expr {int($id - (1 << 24) * double($upper))}]
        set id [expr {(1 << 24) * ($upper & 0xff) + $lower}]
		set asn [expr {$upper >> 8 & 0xffff}]
		if {$asn} {set id $asn:$id}
        regsub "$match" $line "PW neighbor: $ip, ID: $id" line
    }
    catch {puts $line}
}
