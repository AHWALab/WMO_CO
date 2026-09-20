# EF5 pour les Comores, atelier de formation

Installation autonome d'EF5 pour les Comores, à **30 m uniquement**. Le modèle
hydrologique s'exécute dans un conteneur Docker, sans rien changer à la formation
TITO Comores. L'image EF5 est la même (`ef5-container`) que celle utilisée par
TITO ; seule l'organisation des dossiers d'exécution diffère.

Ce paquet contient **une seule résolution (30 m)** et **un seul fichier de
contrôle** : `conf/control_30m.txt`.

L'archive `docker/ef5-container.tar` n'est **pas** fournie. L'image se construit
sur votre machine, à l'étape 2 ci-dessous.

---

## Prérequis

Avant de commencer, vérifiez ces trois points.

1. **Docker est installé et démarré.**
   - Windows et macOS : Docker Desktop, lancé et complètement démarré (l'icône
     de la barre des tâches ne doit plus indiquer « starting »).
   - Linux : le service Docker Engine est actif.
   - Pour vérifier : `docker info` doit répondre sans erreur.
2. **Une connexion internet** est nécessaire une seule fois, à l'étape 2, pour
   compiler l'image EF5 (quelques minutes).
3. **Windows uniquement** : travaillez depuis l'**invite de commandes (CMD)**.
   Aucun script PowerShell n'est fourni, ce qui évite les blocages liés aux
   stratégies de groupe.

---

## Étape 1. Placer le dossier de travail au bon endroit

Sous Linux et macOS, aucune action n'est nécessaire : utilisez le dossier tel
qu'il est.

Sous **Windows**, les montages Docker depuis un lecteur réseau (`X:`) échouent
souvent, ou apparaissent vides dans le conteneur. Copiez d'abord le dossier sur
un disque **local** :

```bat
xcopy /E /I X:\WMO_CO C:\EF5_ComorosTraining
cd /d C:\EF5_ComorosTraining
```

Toutes les commandes qui suivent se lancent depuis la racine de ce dossier.

---

## Étape 2. Construire l'image Docker

Cette étape compile EF5 à partir des sources (dépôt AHWALab/EF5). Elle demande
une connexion internet et prend quelques minutes. Elle ne se fait **qu'une
seule fois**.

**Linux et macOS**

```bash
./docker/build_ef5.sh --rebuild
```

**Windows (CMD)**

```bat
docker\build_ef5.cmd -Rebuild
```

**Vérifier que l'image est prête**

```bash
./docker/build_ef5.sh --status
```

```bat
docker\build_ef5.cmd -Status
```

La réponse attendue indique que l'image `ef5-container:latest` est présente.

**Facultatif : sauvegarder l'image pour une réutilisation hors ligne**

```bash
./docker/build_ef5.sh --save
```

```bat
docker\build_ef5.cmd -Save
```

L'image est alors enregistrée dans `docker/ef5-container.tar`. Sur un poste sans
internet, cette archive se recharge ensuite avec `--load` (ou `-Load` sous
Windows).

> **Ordre de réutilisation.** Une fois la première construction faite, les
> scripts cherchent dans cet ordre : l'image déjà présente sur la machine, puis
> l'archive `docker/ef5-container.tar` si elle existe, puis une construction
> depuis `docker/Dockerfile`.

---

## Étape 3. Lancer EF5

Un seul fichier de contrôle existe. Si vous n'en précisez aucun,
`conf/control_30m.txt` est utilisé par défaut.

**Linux, macOS et WSL**

```bash
./run_ef5.sh
```

**Windows (CMD)**

```bat
run_ef5.cmd
```

Variantes équivalentes, si vous préférez nommer le fichier de contrôle :

| Système | Commande |
|---------|----------|
| Linux, WSL, macOS | `./run_ef5.sh conf/control_30m.txt` |
| Windows (CMD) | `run_ef5.cmd -Control control_30m.txt` |
| Tous systèmes | `docker compose run --rm ef5 /ef5/bin/ef5 /conf/control_30m.txt` |

Pour ouvrir un terminal interactif dans le conteneur et inspecter les données :

```bash
./run_ef5.sh --bash
```

```bat
run_ef5.cmd -Bash
```

Sous macOS, Docker Desktop ne gère pas le réseau de l'hôte : `run_ef5.sh`
bascule automatiquement sur `docker compose`. Vous n'avez rien à faire.

---

## Étape 4. Récupérer les résultats

Les sorties sont écrites dans :

```text
output/30m/
```

Elles comprennent les grilles `maxq` (débit maximal), `maxunitq` (débit unitaire
maximal), la précipitation cumulée, et l'humidité du sol lorsque cette sortie est
activée.

---

## Changer la période de simulation

La fenêtre fournie en exemple dans `conf/control_30m.txt` est :

```text
TIME_BEGIN=202404240800
TIME_END=202404270000
```

Modifiez ces deux lignes pour simuler une autre période, au format
`AAAAMMJJHHMM`.

Avant un calcul avec précipitation, déposez les GeoTIFF IMERG dans :

```text
data/precip/
```

Les fichiers doivent être nommés `imerg.qpe.YYYYMMDDHHUU.30minAccum.tif`. Tout
fichier manquant est traité comme une précipitation **nulle**, sans message
d'erreur : vérifiez donc que la série est complète sur la période choisie.

---

## Organisation des dossiers

```text
EF5_ComorosTraining/
├── data/                        monté en /data (entrées du modèle, lecture et écriture)
│   ├── basic/                   MNT, direction d'écoulement (DDM), accumulation (FAM)
│   │   └── DEM_comoros_30m.tif / FDIR_comoros_30m.tif / FAC_comoros_30m.tif
│   ├── parameters/
│   │   ├── CREST_Comoros_30m/
│   │   └── KW_Comoros_30m/
│   ├── pet/                     climatologie d'ETP, PET.01.tif à PET.12.tif
│   ├── states/
│   │   └── 30m/                 états de démarrage à chaud (crest_SM, kwr_*)
│   └── precip/                  forçage IMERG : imerg.qpe.YYYYMMDDHHUU.30minAccum.tif
├── output/                      monté en /output (résultats EF5)
│   └── 30m/                     résultats du domaine 30 m
├── conf/                        monté en /conf (fichiers de contrôle, lecture seule)
│   ├── control_30m.txt          le seul fichier de contrôle, Comores 30 m
│   └── basin_list/
│       └── Comoros_30m_basin_new.txt
├── docker/
│   ├── Dockerfile               construit ef5-container:latest depuis les sources (AHWALab/EF5)
│   ├── build_ef5.sh             construction et réutilisation (Linux et macOS)
│   └── build_ef5.cmd            construction et réutilisation (Windows CMD, sans PowerShell)
├── docker-compose.yml           lanceur multiplateforme (Linux, macOS, Windows)
├── run_ef5.sh                   exécution d'EF5 (Linux, macOS, WSL)
├── run_ef5.cmd                  exécution d'EF5 (Windows CMD, sans PowerShell)
└── README.md
```

### Accès du conteneur aux dossiers

`run_ef5.sh`, `run_ef5.cmd` et `docker-compose.yml` montent les trois dossiers
principaux dans le conteneur et lancent EF5 depuis sa racine. Tous les chemins
du fichier de contrôle sont donc relatifs à `/`.

| Dossier sur la machine | Chemin dans le conteneur | Contenu |
|------------------------|--------------------------|---------|
| `./data` | `/data` | Entrées : basic, parameters, pet, states, precip |
| `./output` | `/output` | Résultats EF5 : maxq, maxunitq, `ts.*.tif`, journaux, CSV |
| `./conf` | `/conf` | Fichiers de contrôle EF5 |

### Fichier de contrôle et sorties

| Fichier de contrôle | Résolution | Domaine | Dossier de sortie | États |
|---------------------|------------|---------|-------------------|-------|
| `conf/control_30m.txt` | 30 m | Comores | `./output/30m/` | `data/states/30m/` |

La liste des bassins et exutoires, fournie à titre de référence, se trouve dans
`conf/basin_list/Comoros_30m_basin_new.txt`.

---

## Problèmes fréquents

| Symptôme | Cause probable et solution |
|----------|----------------------------|
| `docker info` échoue | Docker Desktop n'est pas démarré, ou pas complètement. Attendez puis relancez. |
| Le conteneur ne voit aucune donnée sous Windows | Le dossier est sur un lecteur réseau. Copiez-le sur un disque local, voir l'étape 1. |
| `control file not found` | Le fichier de contrôle doit se trouver dans `conf/`. Vérifiez le nom exact. |
| La construction échoue à l'étape 2 | Pas d'accès internet au moment du clonage d'AHWALab/EF5. Reconnectez-vous et relancez `--rebuild`. |
| Résultats vides ou précipitation nulle | Fichiers IMERG absents de `data/precip/` pour la période simulée. |

Lancement direct, sans passer par les scripts :

```bat
docker compose build
docker compose run --rm ef5 /ef5/bin/ef5 /conf/control_30m.txt
```

---

## Contact

Mohamed Abdelkader, mohamed-abdelkader@uiowa.edu
Vanessa Robledo, vanessa-robledodelgado@uiowa.edu
Laboratoire AHWA, [ahwa.lab.uiowa.edu](https://ahwa.lab.uiowa.edu/), engr-ahwa-lab@uiowa.edu
