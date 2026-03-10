#!/bin/bash

function check_os {
    lsb_release -a || sw_version
}

function homebrew_install {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

function install_minikube {
    local home_brew_check=$(which brew)
    local docker_check=$(which docker)
    if ! home_brew_check; then
                read install_home_brew
                if install_home_brew == "y"; then
                echo "Installing Homebrew on Mac"
                homebrew_install()
                else
                echo "Installing Minikube without Homebrew"
                fi
                curl -Lo minikube https://github.com/kubernetes/minikube/releases/latest/download/minikube-darwin-armd64
                chmod +x minikube
    else
        if ! docker_check; then
        
        else
        brew install minikube
        fi
    fi
}


#Verify that minikube is installed
if ! command -v minikube &> /dev/null
then
    echo "minikube could not be found, do you want to install it now? (y/n)"
    read install_minikube
    case install_minikube in
    y)
    if [ check_os == "MacOS"]; then 
    ;;
    esac
    exit
fi 

#verify that helm is installed
if ! command -v helm &> /dev/null
then
    echo "helm could not be found, please install it first."
    exit
else
    HELM_VERSION=$(helm version --short | grep -oE 'v[0-9]+' | sed 's/v//')
    if [[ $HELM_VERSION -lt 3 ]]; then
        echo "Helm version 3 or higher is required. Please upgrade your Helm installation."
        exit
    fi
fi

#verify that kubectl is running and can successfully connect to minikube
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found, please install it first."
    exit
elif ! kubectl version --short &> /dev/null
then
    echo "kubectl is not able to connect to a Kubernetes cluster. Please ensure minikube is running."
    exit
fi

