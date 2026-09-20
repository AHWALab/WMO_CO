# TITO, formation Comores

**Threading Inputs to Outputs (TITO)** est le cadre développé par le laboratoire
AHWA pour exécuter le modèle hydrologique **EF5** avec des estimations de
précipitation par satellite (QPE), des prévisions d'ensemble à très courte
échéance (nowcast et QPF) et, en option, la cartographie des zones inondées
(FIM).

Ce dossier est le **paquet de formation Comores**, une copie allégée de TITO
prête pour la salle de cours, centrée sur les **Comores** à **30 m uniquement**.
Il ne s'agit pas de l'arborescence opérationnelle complète Caraïbes et Comores.

**Cas d'étude de la formation, fixe :** rejeu (hindcast) du
**2024-04-27 00:00 au 2024-04-27 00:00 UTC**, soit un seul cycle.
Les états de démarrage à chaud sont déjà fournis.

Les partenaires ont besoin de **Docker ou d'Apptainer/Singularity, pas des deux**.

---

## Prérequis

1. **Docker Desktop** (Windows et macOS), **Docker Engine** ou **Apptainer**
   (Linux et HPC), installé et démarré.
2. Les archives d'images sur la clé USB, à placer dans `dist/docker-archives/`
   (elles ne sont pas sur GitHub) :

   ```text
   dist/docker-archives/tito_latest.tar.gz
   dist/docker-archives/ef5-container_latest.tar.gz
   ```
3. Un navigateur web, pour ouvrir l'assistant de configuration. Aucun serveur
   n'est nécessaire.
4. Sous Windows, utilisez l'**invite de commandes (CMD)**. Les lanceurs
   `tito-run.cmd` et `load-docker-images.cmd` sont écrits en CMD pur, afin que
   les stratégies de groupe et le blocage des scripts `.ps1` non signés ne
   s'appliquent pas.

---

## Étape 1. Charger les images Docker

Démarrez d'abord Docker Desktop (Windows et macOS) ou le démon Docker (Linux),
puis chargez les images une seule fois.

**Linux et macOS**

```sh
./load-docker-images.sh
```

**Windows (CMD)**

```bat
load-docker-images.cmd
```

Vous pouvez aussi utiliser `./tito-run.sh load-images` ou
`tito-run.cmd load-images`. Le premier `tito-run` charge d'ailleurs
automatiquement les images manquantes depuis `dist/` si Docker est démarré.

**Vérifier**

```sh
docker images tito
docker images ef5-container
```

Vous devez voir `tito:latest` et `ef5-container:latest`. Une erreur 502 pendant
`docker load` signifie presque toujours que Docker Desktop n'a pas fini de
démarrer : redémarrez Docker et recommencez.

---

## Étape 2. Régler la configuration avec l'assistant

Ouvrez [`trainings/TITO_Setup_Wizard.html`](trainings/TITO_Setup_Wizard.html)
dans un navigateur, en local.

Parcourez les quatre écrans dans l'ordre : mode d'exécution, régions, forçages,
puis revue.

| Écran | Valeurs retenues pour la formation |
|-------|------------------------------------|
| **Mode d'exécution** | Hindcast par défaut, **2024-04-27 00:00 au 2024-04-27 00:00 UTC**, Docker par défaut (Apptainer en option) |
| **Régions** | **Comores uniquement**, **30 m uniquement** |
| **Forçages** | STREAM-Sat et StormLab (hindcast), réglage de N_ss, N_sl, de la RAM et de `ef5_max_workers`, estimation de la durée et du pic de RAM |
| **Revue** | Extrait de configuration et commande d'exécution adaptée à votre système |

Les autres pays et les autres choix de résolution ont été retirés pour ce cours.

Reportez ensuite l'extrait affiché dans `Caribbean_Comoros_config.py`.

> **Conseil pour un ordinateur portable.** À 30 m, réglez
> `stream_sat_ensemble_size = 2`, `stormlab_ensemble_size = 2` et
> `ef5_max_workers = 1`. Trop de calculs EF5 en parallèle saturent la mémoire de
> Docker Desktop, ce qui provoque une sortie en erreur **137**.

---

## Étape 3. Lancer le calcul

C'est la commande de la formation.

**Linux, macOS, Git Bash et WSL**

```sh
./tito-run.sh hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros
```

**Windows (CMD, sans PowerShell)**

```bat
tito-run.cmd hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros
```

**Apptainer sur HPC**

```sh
TITO_RUNTIME=apptainer ./tito-run.sh hindcast \
    "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros
```

L'option `--regions Comoros` est obligatoire dans ce paquet : les autres régions
sont verrouillées dans l'assistant.

Ajoutez **`--offline`** pour ne télécharger aucune précipitation et travailler
depuis l'archive locale. Voir la section « Mode hors ligne ».

---

## Étape 4. Retrouver les résultats

Les sorties sont rangées par cycle, puis par région et résolution, puis par
produit :

```text
outputs/20240427.000000/comoros_30m/
  stream_sat/ensOut1/
  stormlab/ensOut1_sl1/
  imerg/
  gfs/
  fim/stream_sat_stormlab/
```

---

## Mode hors ligne

Mode prévu pour la salle de cours, sans réseau. Il **ne change rien** à la chaîne
en ligne tant que `--offline` n'est pas passé en option.

Ce qui se passe alors :

1. Le lanceur pose `TITO_OFFLINE=1` et monte `offline/` et `offline_precips/`.
2. `prepare_cycle_precip` **refuse tout téléchargement** et prépare les données
   depuis `offline_precips/`.
3. Si vous demandez moins de membres que l'archive n'en contient, ce sont les
   membres **les plus pluvieux** qui deviennent `ensP1…N` et `ensQ1…N`.
4. EF5 et FIM s'exécutent ensuite normalement. Le démarrage à chaud reste
   désactivé, les états étant déjà présents dans `EF5_conf/states/`.

**Seule date autorisée :** `2024-04-27 00:00` UTC (`202404270000`). Tout autre
horodatage provoque un arrêt immédiat. Utilisez le mode en ligne pour d'autres
dates.

```sh
./tito-run.sh hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros --offline
```

```bat
tito-run.cmd hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros --offline
```

Organisation de l'archive, déjà remplie dans ce paquet :

```text
offline_precips/
  stream_sat/comoros/ensP1..10/
  stormlab/comoros/ensQ1..5/
  precipEF5/comoros_30m/
```

Pour la régénérer après une exécution en ligne réussie :
`bash offline/materialize_offline_precips.sh`.
Voir aussi [offline/README.md](offline/README.md).

---

## Autres commandes utiles

```sh
./tito-run.sh load-images          # charger les archives de la clé USB
./tito-run.sh shell                # terminal interactif dans le conteneur
```

Mode opérationnel, qui n'est pas le mode par défaut du cours :

```sh
./tito-run.sh operational --regions Comoros
```

```bat
tito-run.cmd operational --regions Comoros
```

---

## Ce que contient le paquet

| Composant | Rôle |
|-----------|------|
| **EF5** | Modèle hydrologique distribué (CREST et onde cinématique) à **30 m**. Binaire glibc local, ou image Docker associée. |
| **STREAM-Sat** | QPE satellitaire d'ensemble (IMERG et vents U/V GFS à 850 hPa). Voir [Li et al. (2023)](https://doi.org/10.1029/2022WR033752) et Hartke et al. (2022). Code : `tito_utils/qpe_utils/STREAM-Sat-realtime/`. |
| **StormLab** | Prévision d'ensemble de précipitation issue de GEFS et GFS (Liu, Wright et Lorenz, 2024 ; Peng et al., 2025). Domaine `comoros`. Code : `tito_utils/qpf_utils/StormLab-GFS-realtime/`. Dans ce paquet, StormLab est utilisé comme **QPE**, sans le bloc `PRECIPFORECAST` d'EF5. |
| **IMERG / HSAF avec GFS ou AROME** | Chaîne déterministe : QPE, puis prévision utilisée comme QPE. C'est la voie opérationnelle de la formation. |
| **FIM** | Cartographie de l'inondation par bibliothèque de scénarios, **après la phase de prévision**, à **30 m**, sur 55 communes ADM3. Détails dans [README_FIM.md](README_FIM.md) et [fim_store/Comoros/README_Comoros.md](fim_store/Comoros/README_Comoros.md). |

### Chaînes EF5 en mode QPE seule

| Mode | Phase A | Phase B | Phase C |
|------|---------|---------|---------|
| **Hindcast STREAM-Sat et StormLab** | QPE STREAM-Sat plus 6 h sans pluie, vers `states/stream_sat/ensS*/` | ignorée | StormLab en QPE, plus période sans pluie, par membre SS x SL |
| **Opérationnel STREAM-Sat et StormLab** | identique | QPE HSAF de comblement, plus période sans pluie | StormLab en QPE à partir des états de comblement |
| **Opérationnel IMERG avec GFS ou AROME** | QPE IMERG plus période sans pluie à T moins 4 h | comblement SCaMPR plus période sans pluie à T | GFS ou AROME en QPE à partir des états de comblement |
| **Opérationnel HSAF avec GFS ou AROME** | QPE HSAF jusqu'à T, avec sauvegarde des états | ignorée | GFS ou AROME en QPE |

Les couples IMERG/HSAF et le modèle AROME sont réservés à l'opérationnel. La
formation en rejeu utilise STREAM-Sat et StormLab. AROME ne dispose d'aucune
archive de rejeu.

---

## Structure des dossiers

```text
TITO_Comoros/
  Caribbean_Comoros_config.py   # configuration principale (régions, ensembles, FIM, workers EF5)
  orchestrator.py               # un cycle
  hindcast_manager.py           # boucle horaire de rejeu
  tito-run.sh / tito-run.cmd    # lanceur Docker, Apptainer ou natif
  load-docker-images.sh/.cmd    # chargement des images de la clé USB
  trainings/TITO_Setup_Wizard.html
  tito_utils/
    qpe_utils/STREAM-Sat-realtime/   # STREAM-Sat
    qpf_utils/StormLab-GFS-realtime/ # StormLab
    ef5/                             # fichiers de contrôle, tâches, environnements
    fim_utils/                       # FIM
    precip/                          # façade précipitation, avec garde-fou hors ligne
  EF5/bin/ef5                   # binaire EF5 local (Apptainer)
  EF5_conf/
    basic/  parameters/  pet/   templates/
    states/                     # stream_sat/ensS*, imerg/, etc.
    precip/                     # stream_sat, stormlab, imerg
    precipEF5/  qpf_store/
  outputs/<cycle>/<region_res>/<produit>/   # sorties EF5 et FIM, rangées par cycle
  offline/  offline_precips/    # mode hors ligne de la formation
  fim_config/  fim_store/       # YAML des sites FIM et magasin zarr
  dist/docker-archives/         # images de la clé USB (ignorées par git)
```

### États, séparés par produit

| Chaîne | Emplacement des états |
|--------|-----------------------|
| STREAM-Sat | `EF5_conf/states/stream_sat/ensS<n>/<region>_<res>/` |
| IMERG | `EF5_conf/states/imerg/<region>_<res>/` |
| Comblement HSAF (opérationnel STREAM-Sat) | produit de comblement HSAF dans `EF5_conf/states/` |
| Comblement SCaMPR (opérationnel IMERG) | `EF5_conf/states/scampr_det/` |

L'instantané de démarrage à chaud utilisé pour le cycle de 00:00 est
`…/*_20240426_2300.tif`.

---

## Points clés de la configuration

Fichier `Caribbean_Comoros_config.py` :

```python
model_resolution = "30m"
region_resolution_map = {"Comoros": "30m"}
regions_to_run = ["Comoros"]

region_forcing_map = {
    "Comoros": {"qpe_source": "STREAM_SAT", "qpf_source": "STORMLAB"},
}

stream_sat_ensemble_size = 10                 # 2 sur portable, 10 par défaut
stormlab_ensemble_size = 5
ef5_max_workers = 1                           # 1 = EF5 séquentiel, le plus sûr
dry_run_hours = 6
warmup_enabled = False                        # rejeu de formation : états déjà fournis
fim_enabled = True                            # 30 m, et seulement après la prévision
```

Modèle de fichier de contrôle à 30 m :
`EF5_conf/templates/ef5_Comoros_30m_control_template.txt`

FIM : décompressez les magasins une seule fois avec
`python fim_store/unzip_stores.py`. Voir [README_FIM.md](README_FIM.md).

### Paquets de l'environnement du conteneur

Définis dans `tito_env.yml` (Python 3.12, conda-forge). **Sans PyTorch ni CUDA.**

| Domaine | Paquets |
|---------|---------|
| Tableaux et calcul scientifique | numpy, scipy, pandas, xarray, netcdf4, h5py |
| SIG | gdal, rasterio, rioxarray, pyproj, shapely |
| Bruit STREAM-Sat | pysteps (FFT uniquement) |
| GFS et GRIB | cfgrib, eccodes, herbie-data, boto3 |
| FIM | zarr, pyyaml |
| Entrées et sorties | requests, pillow, tifffile, matplotlib-base |

Après modification de ce fichier, reconstruisez l'image TITO :
`./container-build.sh --no-ef5`.

---

## Apptainer et HPC

```sh
TITO_RUNTIME=apptainer ./tito-run.sh hindcast \
    "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros --offline
```

Cette voie utilise `tito.sif` et le binaire **local** `EF5/bin/ef5`, sans
Apptainer imbriqué. Les bibliothèques `libtiff`, `libgeotiff` et `libgomp`
doivent être présentes dans l'image TITO, ce qui est le cas du Dockerfile actuel.
Une sortie en erreur **127** signale en général une bibliothèque partagée
manquante : reconstruisez l'image TITO.

Pour convertir une archive Docker sur le HPC : `./docker-to-apptainer.sh`.

---

## Réinitialiser après un plantage

Si une exécution s'interrompt en cours de route (mémoire saturée, GeoTIFF
corrompus, états écrits à moitié, précipitations résiduelles), remettez TITO dans
l'état initial de la formation avant de relancer le cycle du
**2024-04-27 00:00**.

| Système | Commande |
|---------|----------|
| Linux et macOS | `./reset_tito.sh` |
| Aperçu seul | `./reset_tito.sh --dry-run` |
| Windows CMD | `reset_tito.cmd` |
| Aperçu seul sous Windows | `reset_tito.cmd --dry-run` |

Ce que fait la réinitialisation :

- Elle vide le contenu de `outputs/`, `EF5_conf/precip/`, `EF5_conf/precipEF5/`
  et `EF5_conf/qpf_store/`.
- Elle vide les dossiers de sortie de STREAM-Sat et de StormLab.
- Elle **conserve** les GeoTIFF d'état du démarrage à chaud du
  **2024-04-26 23:00** (`20240426_2300` et les variantes d'écriture courantes),
  et supprime les autres fichiers `*.tif` sous `EF5_conf/states/`.
- Elle ne supprime jamais les **dossiers** d'états.
- Si aucun état de 23:00 n'est trouvé, elle **refuse** de supprimer le moindre
  fichier d'état, sauf si `--force` est passé.

Relancez ensuite le rejeu de formation, avec `--offline` si vous ne voulez aucun
téléchargement :

```sh
./tito-run.sh hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros --offline
```

```bat
tito-run.cmd hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros --offline
```

Le dossier `offline_precips/` n'est **pas** vidé : la prochaine exécution
`--offline` y repuisera les précipitations.

---

## Dépannage

| Symptôme | Cause probable |
|----------|----------------|
| Erreur 502 pendant `docker load` | Docker Desktop n'est pas prêt. Redémarrez le démon. |
| EF5 sort en erreur **137** | Mémoire saturée. Réduisez les ensembles, posez `ef5_max_workers=1`, augmentez la RAM allouée à Docker. |
| EF5 sort en erreur **127** | `libtiff.so.5` manquante pour l'EF5 local. Reconstruisez l'image TITO. |
| `Cannot open TIFF` après STREAM-Sat | GeoTIFF corrompus par manque de mémoire. Supprimez `EF5_conf/precip/stream_sat` et relancez. |
| FIM renvoie `no_runs` | La chaîne ne correspond pas aux dossiers. Vérifiez `outputs/<cycle>/<rkey>/stormlab/`. |
| Le cycle est refusé en mode hors ligne | Seul le 27 avril 2024 à 00:00 UTC est autorisé. |
| Le mode hors ligne télécharge quand même | Ancienne voie Apptainer. Le lanceur actuel affiche `Offline : YES` et `OFFLINE precip (hard guard…)`. |

---

## Références

- Li, Z., et al. (2023). STREAM-Sat, ensemble de QPE satellitaire. *Water Resources Research*.
- Hartke, S., et al. (2022). Travaux associés sur les ensembles de précipitation satellitaire.
- Liu, G., Wright, D. B., et Lorenz, D. (2024). StormLab.
- Peng, B., et al. (2025). Applications de StormLab et de GEFS.
- EF5 : [AHWALab/EF5-builder-toolkit](https://github.com/AHWALab/EF5-builder-toolkit)

---

## Contact

Mohamed Abdelkader, mohamed-abdelkader@uiowa.edu
Vanessa Robledo, vanessa-robledodelgado@uiowa.edu
Laboratoire AHWA, [ahwa.lab.uiowa.edu](https://ahwa.lab.uiowa.edu/), engr-ahwa-lab@uiowa.edu

## Citation

Robledo Delgado, V., et Vergara, H. (2025). Threading Inputs to Outputs (TITO)
(v2.0.0). Zenodo. https://doi.org/10.5281/zenodo.17246491
