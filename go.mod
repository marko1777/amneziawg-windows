module github.com/amnezia-vpn/amneziawg-windows

go 1.23

replace github.com/amnezia-vpn/amneziawg-go v0.2.12 => github.com/marko1777/amneziawg-go v0.1.0

require (
	// github.com/marko1777/amneziawg-go v0.1.0
	golang.org/x/crypto v0.33.0
	golang.org/x/sys v0.30.0
	golang.org/x/text v0.22.0
)

require github.com/amnezia-vpn/amneziawg-go v0.2.12

require (
	github.com/aarzilli/golua v0.0.0-20241229084300-cd31ab23902e // indirect
	github.com/tevino/abool/v2 v2.1.0 // indirect
	golang.org/x/net v0.35.0 // indirect
	golang.zx2c4.com/wintun v0.0.0-20230126152724-0fa3db229ce2 // indirect
)
