#!/bin/bash
set -e -x

# Install a system package required by our library
yum install -y atlas-devel
ARGS=("$@")

PLAT=${ARGS[0]}

PYBINS=${ARGS[@]:1}
# Compile wheels
echo "${PYBINS[@]}"
for PYBIN in ${PYBINS[@]};do
  PYBIN="/opt/python/${PYBIN}/bin"
  echo ${PYBIN}
  "${PYBIN}/pip" install -r /io/dev-requirements.txt
  "${PYBIN}/python" -m spacy download en
  "${PYBIN}/pip" wheel /io/ -w wheelhouse/
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    if [[ "$whl" == "PyRuSH*" ]]; then
      auditwheel repair "$whl" --plat $PLAT -w /io/wheelhouse/
    else
      rm "$whl"
    fi
done

ls /io/wheelhouse -l
cd /io/wheelhouse
# Install packages and test
for PYBIN in ${PYBINS[@]}; do
    PYBIN="/opt/python/${PYBIN}/bin"
    "${PYBIN}/pip" install PyRuSH --no-index -f /io/wheelhouse
    (cd "$HOME"; "${PYBIN}/nosetests" PyRuSH)
done