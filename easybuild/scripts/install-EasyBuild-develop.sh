#!/usr/bin/env bash

# Stop in case of error
set -e

###########################
# Helpers functions
###########################

# Print script help
print_usage()
{
    echo "Usage: $0 <github_username> <install_dir>"
    echo
    echo "    github_username:     username on GitHub for which the EasyBuild repositories should be cloned"
    echo
    echo "    install_dir:         directory were all the EasyBuild files will be installed"
    echo
}

# Clone one branch
github_clone_branch()
{
    REPO="$1"
    BRANCH="$2"

    cd "${INSTALL_DIR}"
    echo "=== Cloning ${GITHUB_USERNAME}/${REPO} ..."
    git clone --branch master git@github.com:${GITHUB_USERNAME}/${REPO}.git

    echo "=== Adding and fetching HPC-UGent GitHub repository @ hpcugent/{$REPO} ..."
    cd "${REPO}"
    git remote add "github_hpcugent" "git@github.com:hpcugent/${REPO}.git"
    git fetch github_hpcugent
    
    # If branch is not 'master', track and checkout it
    if [ "$BRANCH" != "master" ] ; then
        echo "=== Checking out the '${BRANCH}' branch ..."
        git branch --track "${BRANCH}" "github_hpcugent/${BRANCH}"
        git checkout "${BRANCH}"
    fi
}

# Print the content of the module
print_devel_module()
{
cat <<EOF
#%Module

proc ModulesHelp { } {
    puts stderr {   EasyBuild is a software build and installation framework
written in Python that allows you to install software in a structured,
repeatable and robust way. - Homepage: http://hpcugent.github.com/easybuild/

This module provides the development version of EasyBuild.
}
}

module-whatis {EasyBuild is a software build and installation framework
written in Python that allows you to install software in a structured,
repeatable and robust way. - Homepage: http://hpcugent.github.com/easybuild/

This module provides the development version of EasyBuild.
}

set root    "${INSTALL_DIR}"

conflict    EasyBuild

prepend-path    PATH            "\$root/easybuild-framework"

prepend-path    PYTHONPATH      "\$root/vsc-base/lib"
prepend-path    PYTHONPATH      "\$root/easybuild-framework"
prepend-path    PYTHONPATH      "\$root/easybuild-easyblocks"
prepend-path    PYTHONPATH      "\$root/easybuild-easyconfigs"

EOF
}




###########################
# Beginning of the script
###########################


# Check for 'help' argument
if [ "$1" = "-h" -o "$1" = "--help" ] ; then 
    print_usage
    exit 0
fi

# Check the number of parameters
if [ $# -ne 2 ] ; then
    echo "Error: invalid arguments"
    echo
    print_usage
    exit 1
fi

# Read parameters
GITHUB_USERNAME="$1"
INSTALL_DIR="$2"

# Create install directory
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"
INSTALL_DIR="${PWD}" # get the full path

# Clone repository for vsc-base dependency with 'master' branch
github_clone_branch "vsc-base"   "master"

# Clone code repositories with the 'develop' branch
github_clone_branch "easybuild-framework"   "develop"
github_clone_branch "easybuild-easyblocks"  "develop"
github_clone_branch "easybuild-easyconfigs" "develop"

# Clone base repository with the 'master' branch
github_clone_branch "easybuild" "master"

# Clone wiki repository with the 'master' branch
github_clone_branch "easybuild-wiki" "master"

# Create the module file
EB_DEVEL_MODULE_NAME="EasyBuild-develop"
EB_DEVEL_MODULE="${INSTALL_DIR}/${EB_DEVEL_MODULE_NAME}"
print_devel_module > "${EB_DEVEL_MODULE}"
echo 
echo "=== Run 'module use ${INSTALL_DIR}' and 'module load ${EB_DEVEL_MODULE_NAME}' to use your development version of EasyBuild."
echo "=== (you can append ${INSTALL_DIR} to your MODULEPATH to make this module always available for loading)"
echo
echo "=== To update each repository, run 'git pull origin' in each subdirectory of ${INSTALL_DIR}"
echo

exit 0


