#!/usr/bin/env bash
# ============================================================================
# run_ef5.sh : exécuter EF5 (Docker) dans l'espace de travail EF5_ComorosTraining
# ============================================================================
# Le conteneur Docker EF5 accède aux dossiers de l'espace de travail par des
# montages bind :
#
#   ./data    -> /data    (entrées du modèle : basic, parameters, pet, states, precip)
#   ./output  -> /output  (résultats EF5 : maxq/maxunitq/ts*.tif, séries csv)
#   ./conf    -> /conf    (fichier de contrôle EF5, monté en lecture seule)
#
# Les chemins de conf/control_30m.txt sont relatifs à la racine du conteneur (/),
# par exemple :
#   DEM=data/basic/DEM_comoros_30m.tif
#   OUTPUT=output/30m
#   STATES=data/states/30m/
#
# Systèmes :
#   Linux          -> docker run optimisé (réseau de l'hôte, ressources complètes)
#   macOS          -> docker compose (Docker Desktop n'a pas le réseau de l'hôte)
#   Windows        -> utiliser run_ef5.cmd ou `docker compose run --rm ef5`
#
# Utilisation :
#   ./run_ef5.sh                          # exécution avec conf/control_30m.txt
#   ./run_ef5.sh conf/control_30m.txt     # identique, fichier de contrôle explicite
#   ./run_ef5.sh --bash                   # terminal interactif (inspecter les données)
#
# L'image est préparée par docker/build_ef5.sh (réutilisation, chargement ou
# construction).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="${EF5_IMAGE:-ef5-container:latest}"
CONTROL_FILE="${1:-conf/control_30m.txt}"

# --- Détection du système ----------------------------------------------------
OS="$(uname -s)"
case "$OS" in
    Darwin) PLATFORM="macos" ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "Windows détecté. Utilisez plutôt le lanceur CMD :" >&2
        echo "    run_ef5.cmd -Control control_30m.txt" >&2
        echo "  ou directement : docker compose run --rm ef5" >&2
        exit 1
        ;;
    *) PLATFORM="linux" ;;
esac

# --- Détection des ressources de la machine ----------------------------------
if [[ "$PLATFORM" == "macos" ]]; then
    TOTAL_CPUS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
else
    TOTAL_CPUS=$(nproc)
fi
SHM_SIZE="32g"
NOFILE_LIMIT="1048576"

# --- S'assurer que l'image est disponible (réutiliser / charger / construire) -
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo ">>> Image ${IMAGE_NAME} introuvable. Préparation en cours..."
    bash "${SCRIPT_DIR}/docker/build_ef5.sh"
fi

# --- Mode terminal interactif -------------------------------------------------
if [[ "${1:-}" == "--bash" ]] || [[ "${1:-}" == "-b" ]]; then
    if [[ "$PLATFORM" == "macos" ]]; then
        echo "Ouverture d'un terminal interactif dans le conteneur EF5 (docker compose)..."
        exec docker compose run --rm ef5 /bin/sh
    fi
    echo "Ouverture d'un terminal interactif dans le conteneur EF5..."
    echo "  /data    -> ${SCRIPT_DIR}/data    (entrées)"
    echo "  /output  -> ${SCRIPT_DIR}/output  (résultats)"
    echo "  /conf    -> ${SCRIPT_DIR}/conf    (fichiers de contrôle)"
    exec docker run -it --rm \
        --network host --ipc host \
        --shm-size="${SHM_SIZE}" \
        --ulimit nofile="${NOFILE_LIMIT}:${NOFILE_LIMIT}" \
        --security-opt seccomp=unconfined \
        -v "${SCRIPT_DIR}/data:/data:rw" \
        -v "${SCRIPT_DIR}/output:/output:rw" \
        -v "${SCRIPT_DIR}/conf:/conf:ro" \
        -u "$(id -u):$(id -g)" \
        -e OMP_NUM_THREADS="${TOTAL_CPUS}" \
        -e OMP_PROC_BIND=true \
        -e OMP_PLACES=cores \
        -w / \
        "${IMAGE_NAME}" \
        /bin/sh
fi

# --- Vérification du fichier de contrôle --------------------------------------
# Le fichier de contrôle doit se trouver dans ./conf pour être visible en /conf/<rel>.
CONF_DIR="${SCRIPT_DIR}/conf"
CONTROL_ABS="$(cd "$(dirname "$CONTROL_FILE")" && pwd)/$(basename "$CONTROL_FILE")"
if [[ ! -f "$CONTROL_ABS" ]]; then
    echo "ERREUR : fichier de contrôle introuvable : ${CONTROL_ABS}" >&2
    exit 1
fi
case "$CONTROL_ABS" in
    "${CONF_DIR}"/*) ;;
    *)
        echo "ERREUR : le fichier de contrôle doit se trouver dans ${CONF_DIR}/" >&2
        echo "  Reçu : ${CONTROL_ABS}" >&2
        exit 1
        ;;
esac
CONTROL_IN_CONF="${CONTROL_ABS#"$CONF_DIR"/}"

echo "=============================================="
echo "  EF5 Docker, exécution (${PLATFORM})"
echo "=============================================="
echo "  Image    : ${IMAGE_NAME}"
echo "  Contrôle : ${CONTROL_ABS}"
echo "  Données  : ${SCRIPT_DIR}/data   -> /data"
echo "  Sorties  : ${SCRIPT_DIR}/output -> /output"
echo "  Conf     : ${SCRIPT_DIR}/conf   -> /conf"
echo "  OMP      : ${TOTAL_CPUS} fils d'exécution"
echo "=============================================="

# Docker Desktop (macOS) n'a pas le réseau de l'hôte : passage par docker compose.
if [[ "$PLATFORM" == "macos" ]]; then
    docker compose run --rm \
        -e "OMP_NUM_THREADS=${TOTAL_CPUS}" \
        ef5 /ef5/bin/ef5 "/conf/${CONTROL_IN_CONF}"
    echo ""
    echo "Exécution d'EF5 terminée. Les résultats sont dans ${SCRIPT_DIR}/output/"
    exit 0
fi

docker run --rm \
    --network host --ipc host \
    --shm-size="${SHM_SIZE}" \
    --ulimit nofile="${NOFILE_LIMIT}:${NOFILE_LIMIT}" \
    --ulimit nproc=65535:65535 \
    --ulimit memlock=-1:-1 \
    --security-opt seccomp=unconfined \
    -v "${SCRIPT_DIR}/data:/data:rw" \
    -v "${SCRIPT_DIR}/output:/output:rw" \
    -v "${SCRIPT_DIR}/conf:/conf:ro" \
    -u "$(id -u):$(id -g)" \
    -e OMP_NUM_THREADS="${TOTAL_CPUS}" \
    -e OMP_PROC_BIND=true \
    -e OMP_PLACES=cores \
    -w / \
    "${IMAGE_NAME}" \
    /ef5/bin/ef5 "/conf/${CONTROL_IN_CONF}"

echo ""
echo "Exécution d'EF5 terminée. Les résultats sont dans ${SCRIPT_DIR}/output/"
