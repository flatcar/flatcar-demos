cat "$1" \
    | docker run --rm \
      -v "$(pwd)":/files \
      -i quay.io/coreos/butane:latest \
      --files-dir /files  \
    >"${1/.yaml/.json}"
echo "${1} ==> ${1/.yaml/.json}"
