################################################################################
# EF5 : Ensemble Framework for Flash Flood Forecasting, image Docker
# Image autonome pour l'espace de travail EF5_ComorosTraining.
#
# C'est la même construction Alpine que celle utilisée par TITO. Elle compile
# EF5 depuis le fork AHWALab hébergé sur GitHub et produit l'image
# `ef5-container:latest`. Le conteneur ne contient AUCUNE donnée de modèle :
# toutes les entrées et sorties sont montées au moment de l'exécution
# (voir run_ef5.sh et README.md).
#
# Construction (internet requis pour cloner EF5) :
#   ./docker/build_ef5.sh --rebuild
#
# Réutilisation sans recompiler : l'archive docker/ef5-container.tar peut être
# chargée avec `./docker/build_ef5.sh --load`, sans connexion internet.
################################################################################

ARG DOCKER_BASE_OS="alpine:3.17"

FROM ${DOCKER_BASE_OS} AS ef5-image
LABEL nssl.wrdd.image.authors="jorge.duarte@noaa.gov"

# Volumes montés à l'exécution : /data (entrées), /output (résultats), /conf (contrôle)
VOLUME [ "/data" ]
VOLUME [ "/output" ]
VOLUME [ "/conf" ]

# Mettre à jour l'index des paquets
RUN apk update

# Installer les outils de compilation et les dépendances d'EF5
RUN apk add --no-cache git automake autoconf build-base libgeotiff-dev

# Cloner EF5 depuis GitHub dans le dossier ef5, à la racine de l'image.
# On utilise le fork AHWALab (branche master), qui contient les dernières
# fonctionnalités et corrections.
WORKDIR /
RUN git clone https://github.com/AHWALab/EF5.git ./ef5

# Définir le dossier ef5 comme répertoire de travail
WORKDIR /ef5

# Compiler et installer EF5 avec le support OpenMP et les optimisations
RUN autoreconf --force --install
RUN ./configure
RUN make -j"$(nproc)" CXXFLAGS="-O3 -fopenmp"

# Exécuter EF5 avec le fichier de contrôle monté depuis ./conf
CMD ["/ef5/bin/ef5", "/conf/control.txt"]
