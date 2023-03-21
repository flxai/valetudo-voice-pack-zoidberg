#!/usr/bin/env bash
# Creates a voice pack for vacuum cleaning bots using the audio files in the
# wav dir. If the audio files number is contained within appendix.txt, append
# Zoidberg's woop at the end. Startup (0.ogg) and shutdown (200.ogg) sound are
# only a converted version of Zoidberg's woop.

# Set audio bitrate
ba=64k

# Create temporary directories
tf=$(mktemp -t "voice_pack_XXXXX")
td=$(mktemp -d "voice_pack_ogg_XXXXX")

# Collect commands for audio generation
cd "$(dirname ""$0"")"
for fn in wav/*.wav; do
    f="$(basename ""$fn"")"
    i=${f%%.wav}
    if grep -qE ""^$i\$"" appendix.txt; then
        echo "ffmpeg -y -i '$fn' -i zoidberg.wav -filter_complex '[0:a] [1:a] concat=n=2:v=0:a=1' -vn -c:a libvorbis -b:a '$ba' '$td/$i.ogg'"
    else
        echo "ffmpeg -y -i '$fn' -c:a libvorbis -b:a '$ba' '$td/$i.ogg'"
    fi
done > "$tf"
for i in 0 200; do
    echo "ffmpeg -y -i zoidberg.wav -c:a libvorbis -b:a '$ba' '$td/$i.ogg'"
done >> "$tf"

# Generate audio in parallel
parallel < "$tf"

# Get versino id for release file
cid=$(git rev-parse --short HEAD)
[[ $? -gt 0 ]] && vid="nogit" || vid="$cid"
tid=$(git tag --points-at HEAD)
[[ -z "$tid" || $? -gt 0 ]] || vid="$tid"

# Pack release file
tar czvf "voice-pack-zoidberg-$vid.tar.gz" "$td"

# Remove junk
rm "$tf"
rm -rf "$td"

