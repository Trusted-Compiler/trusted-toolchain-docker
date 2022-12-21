# SPDX-FileCopyrightText: 2022 fosslinux <fosslinux@aussies.space>
#
# SPDX-License-Identifier: GPL-3.0-or-later

src_prepare() {
    default

    # Delete generated files that won't be regenerated
    rm Lib/pydoc_data/topics.py

    rm Modules/_ssl_data*.h # Breaks _ssl module, but it fails anyways

    # Regenerate encodings
    grep generated -r . -l | grep encodings | xargs rm
    mkdir Tools/unicode/in Tools/unicode/out
    mv ../CP437.TXT Tools/unicode/in/
    pushd Tools/unicode
    python gencodec.py in/ ../../Lib/encodings/
    popd

    # Regenerate unicode
    rm Modules/unicodedata_db.h Modules/unicodename_db.h Objects/unicodetype_db.h
    mv ../*.txt ../*.zip .
    python Tools/unicode/makeunicodedata.py

    # Regenerate sre_constants.h
    rm Modules/sre_constants.h
    cp Lib/sre_constants.py .
    python sre_constants.py
    rm sre_constants.py
    mv sre_constants.h Modules/

    # Regenerate stringprep
    rm Lib/stringprep.py
    python Tools/unicode/mkstringprep.py > Lib/stringprep.py

    # Regenerate autoconf
    autoreconf-2.71 -fi
}

src_configure() {
    CPPFLAGS="-U__DATE__ -U__TIME__" \
    LDFLAGS="-L/usr/lib/musl" \
        ./configure \
        --prefix="${PREFIX}" \
        --libdir="${PREFIX}/lib/musl" \
        --with-system-ffi
}

src_compile() {
    # Regenerations
    rm Modules/_blake2/blake2s_impl.c
    make regen-all

    make CPPFLAGS="-U__DATE__ -U__TIME__"
}

src_install() {
    default
    ln -s "${PREFIX}/lib/musl/python3.8/lib-dynload" "${DESTDIR}${PREFIX}/lib/python3.8/lib-dynload"
    ln -s "${PREFIX}/bin/python3.8" "${DESTDIR}${PREFIX}/bin/python"

    # Remove non-reproducible .pyc/o files
    find "${DESTDIR}" -name "*.pyc" -delete
    find "${DESTDIR}" -name "*.pyo" -delete
}
