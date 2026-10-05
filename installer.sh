#!/bin/sh
# MohammedSkin online installer / updater
# Works on OpenViX, OpenBlackHole, OpenATV, PurE2 and EGAMI (Enigma2).
#   wget -q --no-check-certificate "https://raw.githubusercontent.com/mido00020/MohammedSkin/main/installer.sh" -O - | /bin/sh

BASE="https://raw.githubusercontent.com/mido00020/MohammedSkin/main"
IPK="/tmp/enigma2-skin-mohammedskin.ipk"

echo "=============================================="
echo "        MohammedSkin - online installer"
echo "=============================================="

# ---------------------------------------------------------------- which image is this?
value() {
	# value <file> <key>  ->  value of key=... without quotes
	[ -f "$1" ] || return 1
	sed -n "s/^$2[ ]*=[ ]*//p" "$1" | head -n 1 | tr -d "'\"\r"
}

DISTRO=$(value /usr/lib/enigma.info distro)
[ -z "$DISTRO" ] && DISTRO=$(value /etc/image-version distro)
[ -z "$DISTRO" ] && DISTRO=$(value /etc/image-version creator)
[ -z "$DISTRO" ] && [ -f /etc/issue ] && DISTRO=$(head -n 1 /etc/issue | sed 's/Welcome to //' | awk '{print $1}')
[ -z "$DISTRO" ] && [ -f /etc/bhversion ] && DISTRO=openbh
VERSION=$(value /usr/lib/enigma.info imageversion)
[ -z "$VERSION" ] && VERSION=$(value /etc/image-version version)

case "$(echo "$DISTRO" | tr 'A-Z' 'a-z' | tr -d ' _-')" in
	openvix*|vix) IMAGE="OpenViX" ;;
	openbh*|openblackhole*|blackhole*) IMAGE="OpenBlackHole" ;;
	openatv*) IMAGE="OpenATV" ;;
	pure2*) IMAGE="PurE2" ;;
	egami*) IMAGE="EGAMI" ;;
	*) IMAGE="" ;;
esac

if [ -n "$IMAGE" ]; then
	echo "Image: $IMAGE ${VERSION}  (supported)"
else
	echo "Image: ${DISTRO:-unknown} ${VERSION}"
	echo "This image is not on the tested list. The skin adapts itself anyway,"
	echo "the image name in the infobar is left out."
fi

if [ ! -d /usr/lib/enigma2/python ] || ! command -v opkg >/dev/null 2>&1; then
	echo "ERROR: this does not look like an Enigma2 receiver (no enigma2 python or opkg)."
	exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
	echo "ERROR: python3 not found. MohammedSkin needs a Python 3 image."
	exit 1
fi

# ---------------------------------------------------------------- download

fetch() {
	rm -f "$2"
	if wget -q --no-check-certificate "$1" -O "$2" 2>/dev/null && [ -s "$2" ]; then
		return 0
	fi
	if command -v curl >/dev/null 2>&1 && curl -kfsSL "$1" -o "$2" && [ -s "$2" ]; then
		return 0
	fi
	rm -f "$2"
	return 1
}

VER=""
if fetch "$BASE/version.txt" /tmp/mohammedskin_version.txt; then
	VER=$(head -n 1 /tmp/mohammedskin_version.txt | tr -d '\r\n ')
	rm -f /tmp/mohammedskin_version.txt
fi
echo "Latest version: ${VER:-unknown}"

echo "Downloading ..."
if ! fetch "$BASE/ipk/enigma2-skin-mohammedskin_all.ipk" "$IPK"; then
	echo "ERROR: download failed. Check the internet connection."
	exit 1
fi

# ---------------------------------------------------------------- install

echo "Installing ..."
if ! opkg install --force-reinstall --force-overwrite "$IPK"; then
	rm -f "$IPK"
	echo "ERROR: installation failed."
	exit 1
fi
rm -f "$IPK"

# Pillow is optional (used for the clock and theme tools); try to add it quietly.
opkg list-installed 2>/dev/null | grep -q '^python3-pillow ' || opkg install python3-pillow >/dev/null 2>&1

echo "=============================================="
echo "  MohammedSkin ${VER} installed successfully"
[ -n "$IMAGE" ] && echo "  adapted to $IMAGE"
echo "=============================================="

if [ -z "$NORESTART" ]; then
	echo "Restarting the GUI ..."
	sleep 2
	killall -9 enigma2 >/dev/null 2>&1
fi
exit 0
