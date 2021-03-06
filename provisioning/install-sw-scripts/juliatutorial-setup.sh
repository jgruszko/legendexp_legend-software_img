# This software is licensed under the MIT "Expat" License.
#
# Copyright (c) 2017: Oliver Schulz.


DEFAULT_BUILD_OPTS=""


pkg_installed_check() {
    test -f "${INSTALL_PREFIX}/Project.toml"
}


pkg_install() {
    GITHUB_USER=`echo "${PACKAGE_VERSION}" | cut -d '/' -f 1`
    GIT_BRANCH=`echo "${PACKAGE_VERSION}" | cut -d '/' -f 2`
    git clone "https://github.com/${GITHUB_USER}/legend-julia-tutorial" "${INSTALL_PREFIX}"

    export JULIA_DEPOT_PATH="/opt/julia/local/share/julia"
    export JULIA_PROJECT=$(dirname `julia -e 'import Pkg; println(Pkg.project().path)'`)
 
    export JUPYTER_DATA_DIR="/opt/anaconda3/share/jupyter"

    DEFAULT_NUM_THREADS=`lscpu -p | grep '^[0-9]\+,[0-9]\+,[0-9]\+,0,' | cut -d ',' -f 2 | sort | uniq | wc -l`
    export JULIA_NUM_THREADS="${DEFAULT_NUM_THREADS}"
    export OPENBLAS_NUM_THREADS="${DEFAULT_NUM_THREADS}"
    export OMP_NUM_THREADS="${DEFAULT_NUM_THREADS}"

    julia -e 'using Pkg; Pkg.update()'
    cp -a "${INSTALL_PREFIX}"/{Project.toml,Manifest.toml} "${JULIA_PROJECT}"
    julia -e 'import Pkg; Pkg.instantiate()'
    julia -e 'using Pkg; Pkg.add("IJulia"; preserve=Pkg.PRESERVE_ALL); Pkg.build("IJulia")'
    julia -e 'import Pkg; Pkg.precompile()'

    DEFAULT_SYSIMG=`julia -e 'import Libdl; println(abspath(Sys.BINDIR, "..", "lib", "julia", "sys." * Libdl.dlext))'`

    (cd "${INSTALL_PREFIX}" && julia "build_sysimage.jl")
    mv "${DEFAULT_SYSIMG}" "${DEFAULT_SYSIMG}.backup"
    mv "${INSTALL_PREFIX}/JuliaSysimage.so" "${DEFAULT_SYSIMG}"

    rm -rf /opt/julia/local/share/julia/logs
    chmod -R go+rX  "$JULIA_DEPOT_PATH"

    # Test:
    julia -e 'using LegendDataTypes'
}


pkg_env_vars() {
    true
}
