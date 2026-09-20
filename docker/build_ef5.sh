#!/usr/bin/env bash
# ============================================================================
# build_ef5.sh : construire l'image Docker EF5 OU réutiliser une image existante
# ============================================================================
# Gestion de l'image autonome de l'espace de travail EF5_ComorosTraining.
#
# Comportement par défaut (sans option) : RÉUTILISER l'image déjà installée.
#   1. `ef5-container:latest` existe sur la machine         -> la réutiliser
#   2. sinon, si docker/ef5-container.tar est présent       -> le charger (hors ligne)
#   3. sinon                                                -> construire depuis les sources
#
# Options :
#   --rebuild   force une construction neuve depuis docker/Dockerfile (internet
#               requis : clone AHWALab/EF5 depuis GitHub, puis compile)
#   --load      force le chargement de l'image depuis docker/ef5-container.tar
#   --no-cache  reconstruit sans le cache de couches Docker
#   --save      une fois l'image disponible, l'enregistre dans
#               docker/ef5-container.tar (réutilisable sans recompiler)
#   --status    affiche l'image que les scripts d'exécution utiliseront
#
# Utilisation :
#   ./docker/build_ef5.sh                 # réutiliser / charger / construire
#   ./docker/build_ef5.sh --rebuild       # recompiler depuis les sources
#   ./docker/build_ef5.sh --load          # charger depuis l'archive
#   ./docker/build_ef5.sh --save          # enregistrer l'image courante en archive
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="${EF5_IMAGE:-ef5-container:latest}"
ARCHIVE="${SCRIPT_DIR}/ef5-container.tar"

DO_REBUILD=false
DO_LOAD=false
DO_SAVE=false
DO_STATUS=false
NO_CACHE=""

for arg in "$@"; do
    case "$arg" in
        --rebuild) DO_REBUILD=true ;;
        --load) DO_LOAD=true ;;
        --no-cache) NO_CACHE="--no-cache" ;;
        --save) DO_SAVE=true ;;
        --status) DO_STATUS=true ;;
        -h|--help)
            sed -n '2,26p' "$0"
            exit 0
            ;;
        *)
            echo "Option inconnue : $arg" >&2
            exit 1
            ;;
    esac
done

if ! command -v docker >/dev/null 2>&1; then
    echo "ERREUR : docker est introuvable dans le PATH" >&2
    exit 1
fi
if ! docker info >/dev/null 2>&1; then
    echo "ERREUR : impossible de joindre le démon Docker" >&2
    exit 1
fi

image_exists() {
    docker image inspect "$IMAGE_NAME" >/dev/null 2>&1
}

echo "=============================================="
echo "  Image Docker EF5, construction ou réutilisation"
echo "=============================================="
echo "  Image   : ${IMAGE_NAME}"
echo "  Archive : ${ARCHIVE}"
echo "=============================================="

# --status : se contenter de signaler ce qui est disponible
if $DO_STATUS; then
    if image_exists; then
        echo "  Image ef5-container : PRÉSENTE sur la machine (${IMAGE_NAME})"
    elif [[ -f "$ARCHIVE" ]]; then
        echo "  Image ef5-container : NON chargée. Archive présente : ${ARCHIVE}"
        echo "  Chargez-la avec : ./docker/build_ef5.sh --load"
    else
        echo "  Image ef5-container : absente, et aucune archive. Construisez avec --rebuild."
    fi
    exit 0
fi

# --load : forcer le chargement depuis l'archive
if $DO_LOAD; then
    if [[ ! -f "$ARCHIVE" ]]; then
        echo "ERREUR : archive introuvable : ${ARCHIVE}" >&2
        echo "  Construisez d'abord l'image : ./docker/build_ef5.sh --rebuild --save" >&2
        exit 1
    fi
    echo ">>> Chargement de l'image depuis ${ARCHIVE}"
    docker load -i "$ARCHIVE"
    echo ">>> Image chargée."
    $DO_SAVE && { echo ">>> (rien à enregistrer : l'image vient de l'archive)"; DO_SAVE=false; }
    exit 0
fi

# --rebuild : forcer la compilation depuis le Dockerfile
if $DO_REBUILD; then
    echo ">>> Construction de ${IMAGE_NAME} depuis le Dockerfile (compilation d'EF5)..."
    echo "    Internet requis (clone AHWALab/EF5). Compter quelques minutes."
    docker build $NO_CACHE -t "$IMAGE_NAME" .
    echo ">>> Construction terminée."
elif image_exists; then
    echo ">>> Réutilisation de l'image ${IMAGE_NAME}, déjà présente sur la machine."
    echo "    Pour une construction neuve : ./docker/build_ef5.sh --rebuild"
elif [[ -f "$ARCHIVE" ]]; then
    echo ">>> Image absente de la machine. Chargement de l'archive ${ARCHIVE}"
    docker load -i "$ARCHIVE"
    echo ">>> Image chargée depuis l'archive."
else
    echo ">>> Ni image ni archive. Construction depuis le Dockerfile."
    echo "    Internet requis (clone AHWALab/EF5). Compter quelques minutes."
    docker build $NO_CACHE -t "$IMAGE_NAME" .
    echo ">>> Construction terminée."
fi

# --save : enregistrer l'image pour la réutiliser sans recompiler
if $DO_SAVE; then
    echo ">>> Enregistrement de ${IMAGE_NAME} -> ${ARCHIVE}"
    local_tmp="${ARCHIVE}.partial"
    docker save "$IMAGE_NAME" -o "$local_tmp"
    mv -f "$local_tmp" "$ARCHIVE"
    ls -lh "$ARCHIVE"
fi

echo ""
echo "=============================================="
echo "  Terminé. Image : ${IMAGE_NAME}"
echo "  Exécuter EF5 :   ../run_ef5.sh"
echo "  Vérifier l'état : ./build_ef5.sh --status"
echo "=============================================="
