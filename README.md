# TITO — Comoros Training

**Threading Inputs to Outputs (TITO)** is AHWA Lab’s framework for running the **EF5** hydrologic model with satellite QPE, ensemble nowcast/QPF products, and (optionally) flood inundation mapping (FIM).

This folder is the **Comoros training package** — a trimmed, classroom-ready copy of TITO focused on **Comoros** at **30 m only**. It is not the full Caribbean/Comoros operational tree.

**Training case (fixed):** hindcast **2024-04-27 00:00 → 2024-04-27 00:00 UTC** (single cycle).  
Warmup states are already provided. Use the [Setup Wizard](trainings/TITO_Setup_Wizard.html) to pick forcings, ensembles, and RAM, then run the printed command.

Partners need **either Docker or Apptainer/Singularity — not both**.

---

## What this package does

| Piece | Role |
|--------|------|
| **EF5** | Distributed hydrologic model (CREST + KW) at **30 m**. Local glibc binary or sibling Docker image. |
| **STREAM-Sat** | Ensemble satellite QPE (IMERG + GFS 850 hPa U/V motion). See [Li et al. (2023)](https://doi.org/10.1029/2022WR033752), Hartke et al. (2022). Code: `tito_utils/qpe_utils/STREAM-Sat-realtime/`. |
| **StormLab** | Ensemble precipitation forecast from GEFS/GFS (Liu, Wright & Lorenz, 2024; Peng et al., 2025). Domain `comoros`. Code: `tito_utils/qpf_utils/StormLab-GFS-realtime/`. In this package StormLab is run as **QPE** (no EF5 long-range / `PRECIPFORECAST`). |
| **IMERG / HSAF + GFS or AROME** | Deterministic QPE + forecast-as-QPE chain (operational training path). |
| **FIM** | Scenario-library inundation **after the forecast phase**, **30 m**. 55 ADM3 municipalities. Details: [README_FIM.md](README_FIM.md) and [fim_store/Comoros/README_Comoros.md](fim_store/Comoros/README_Comoros.md). |

**QPE-only EF5 chain (no long-range block):**

| Mode | Phase A | Phase B | Phase C |
|------|---------|---------|---------|
| **Hindcast STREAM-Sat + StormLab** | STREAM-Sat QPE + 6 h dry → `states/stream_sat/ensS*/` | skipped | StormLab as QPE + dry (per SS×SL member) |
| **Ops STREAM-Sat + StormLab** | same | HSAF gap QPE + dry | StormLab as QPE from gap states |
| **Ops IMERG + GFS / AROME** | IMERG QPE + dry @ T−4 h | SCaMPR gap + dry @ T | GFS or AROME as QPE from gap states |
| **Ops HSAF + GFS / AROME** | HSAF QPE through T (save states) | skipped | GFS or AROME as QPE |

IMERG/HSAF pairs and AROME are **operational only**. Hindcast training uses STREAM-Sat + StormLab. AROME has no hindcast archive.

---

## Quick start (training)

1. Install **Docker Desktop** (Windows/macOS) or Docker Engine / **Apptainer** (Linux/HPC).
2. Load images (once) — see [Loading Docker images](#loading-docker-images).
3. Open **`trainings/TITO_Setup_Wizard.html`** in a browser (no server needed).
4. Work through: Run mode → Regions → Forcings (RAM + ensembles) → Review.
5. Merge the printed snippet into `Caribbean_Comoros_config.py`.
6. Run the printed command (examples below).

**Intended training command:**

```sh
# Linux / macOS / Git Bash / WSL
./tito-run.sh hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros
```

```bat
REM Windows CMD (no PowerShell)
tito-run.cmd hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros
```

```sh
# HPC Apptainer
TITO_RUNTIME=apptainer ./tito-run.sh hindcast \
    "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros
```

Add **`--offline`** to skip all precip downloads (uses `offline_precips/` — see [Offline mode](#offline-mode)).

---

## Loading Docker images

Place the USB / pendrive archives here (not on GitHub):

```text
dist/docker-archives/tito_latest.tar.gz
dist/docker-archives/ef5-container_latest.tar.gz
```

Start **Docker Desktop** (Windows/macOS) or the Docker daemon (Linux) first.

| Platform | Load once | Then run |
|----------|-----------|----------|
| **Linux / macOS** | `./load-docker-images.sh` or `./tito-run.sh load-images` | `./tito-run.sh hindcast "…" "…" --regions Comoros` |
| **Windows (CMD)** | `load-docker-images.cmd` or `tito-run.cmd load-images` | `tito-run.cmd hindcast "…" "…" --regions Comoros` |

Windows launchers are **pure CMD** (`tito-run.cmd`, `load-docker-images.cmd`) so Group Policy / unsigned `.ps1` blocks do not apply.

The first `tito-run` also **auto-loads** missing images from `dist/` if Docker is up.

**Check:**

```sh
docker images tito
docker images ef5-container
```

Expect `tito:latest` and `ef5-container:latest`. A 502 on `docker load` is usually Docker Desktop not fully started — restart Docker and retry.

---

## Setup Wizard

Open [`trainings/TITO_Setup_Wizard.html`](trainings/TITO_Setup_Wizard.html) locally.

| Step | Training lock-in |
|------|------------------|
| **Run mode** | Hindcast default · **2024-04-27 00:00 → 2024-04-27 00:00 UTC** · Docker default (Apptainer optional) |
| **Regions** | **Comoros only** · **30 m only** |
| **Forcings** | STREAM-Sat + StormLab (hindcast) · set N_ss, N_sl, RAM, `ef5_max_workers` · time / peak-RAM estimate |
| **Review** | Config snippet + OS-specific run command |

Removed for this course: other countries, extra resolution choices.

**Laptop tip:** 30 m, `stream_sat_ensemble_size = 2`, `stormlab_ensemble_size = 2`, `ef5_max_workers = 1`.  
Many parallel EF5 jobs can OOM on Docker Desktop (exit **137**).

---

## Run commands (all OS)

### Hindcast (training window)

| OS | Command |
|----|---------|
| Linux / macOS | `./tito-run.sh hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros` |
| Windows CMD | `tito-run.cmd hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros` |
| Apptainer HPC | `TITO_RUNTIME=apptainer ./tito-run.sh hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros` |

### Offline (no downloads)

Same as above, add `--offline`. Only **2024-04-27 00:00 UTC** is allowed.

```sh
./tito-run.sh hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros --offline
```

```bat
tito-run.cmd hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros --offline
```

### Operational (not the classroom default)

```sh
./tito-run.sh operational --regions Comoros
tito-run.cmd operational --regions Comoros
```

### Helpful extras

```sh
./tito-run.sh load-images          # load USB archives
./tito-run.sh shell                # interactive container shell
```

`--regions Comoros` is required for this package (other regions are locked in the wizard).

---

## Offline mode

Classroom / no-network mode. **Does not change the online pipeline** unless `--offline` is set.

1. Launcher sets `TITO_OFFLINE=1` and bind-mounts `offline/` + `offline_precips/`.
2. `prepare_cycle_precip` **refuses downloads** and stages from `offline_precips/`.
3. If you request fewer ensembles than the archive, the **wettest** members become `ensP1…N` / `ensQ1…N`.
4. EF5 + FIM then run as usual. Warmup stays off (states already in `EF5_conf/states/`).

**Allowed time only:** `2024-04-27 00:00` UTC (`202404270000`). Any other timestamp **fails fast** (use online mode for other dates).

Archive layout (already populated in this package):

```text
offline_precips/
  stream_sat/comoros/ensP1..10/
  stormlab/comoros/ensQ1..5/
  precipEF5/comoros_30m/
```

Refresh after a good online run: `bash offline/materialize_offline_precips.sh`  
More: [offline/README.md](offline/README.md).

---

## Folder structure

```text
TITO_Comoros/
  Caribbean_Comoros_config.py   # main config (regions, ensembles, FIM, EF5 workers)
  orchestrator.py               # one cycle
  hindcast_manager.py           # hourly hindcast loop
  tito-run.sh / tito-run.cmd    # Docker / Apptainer / native launcher
  load-docker-images.sh/.cmd    # load USB images
  trainings/TITO_Setup_Wizard.html
  tito_utils/
    qpe_utils/STREAM-Sat-realtime/   # STREAM-Sat
    qpf_utils/StormLab-GFS-realtime/ # StormLab
    ef5/                             # control files, jobs, runtimes
    fim_utils/                       # FIM
    precip/                          # precip facade (+ offline hard guard)
  EF5/bin/ef5                   # local EF5 binary (Apptainer)
  EF5_conf/
    basic/  parameters/  pet/   templates/
    states/                     # stream_sat/ensS*, imerg/, …
    precip/                     # stream_sat, stormlab, imerg
    precipEF5/  qpf_store/
  outputs/<cycle>/<region_res>/<product>/   # cycle-first EF5 + FIM
  offline/  offline_precips/    # training offline mode
  fim_config/  fim_store/       # FIM site YAML + zarr store
  dist/docker-archives/         # USB images (gitignored)
```

### Cycle-first outputs

```text
outputs/20240427.000000/comoros_30m/
  stream_sat/ensOut1/
  stormlab/ensOut1_sl1/
  imerg/
  gfs/
  fim/stream_sat_stormlab/
```

### States (keep separate per product)

| Chain | States |
|--------|--------|
| STREAM-Sat | `EF5_conf/states/stream_sat/ensS<n>/<region>_<res>/` |
| IMERG | `EF5_conf/states/imerg/<region>_<res>/` |
| HSAF gap (ops STREAM-Sat) | `EF5_conf/states/` gap product for HSAF |
| SCaMPR gap (ops IMERG) | `EF5_conf/states/scampr_det/` |

Training warmup snapshot used for the 00:00 cycle: `…/*_20240426_2300.tif`.

---

## Packages (container env)

Defined in `tito_env.yml` (Python 3.12, conda-forge). **No PyTorch/CUDA.**

| Area | Packages |
|------|----------|
| Arrays / science | numpy, scipy, pandas, xarray, netcdf4, h5py |
| GIS | gdal, rasterio, rioxarray, pyproj, shapely |
| STREAM-Sat noise | pysteps (FFT only) |
| GFS / GRIB | cfgrib, eccodes, herbie-data, boto3 |
| FIM | zarr, pyyaml |
| I/O | requests, pillow, tifffile, matplotlib-base |

Rebuild the TITO image after changing this file: `./container-build.sh --no-ef5`.

---

## Config highlights (`Caribbean_Comoros_config.py`)

```python
model_resolution = "30m"
region_resolution_map = {"Comoros": "30m"}
regions_to_run = ["Comoros"]

region_forcing_map = {
    "Comoros": {"qpe_source": "STREAM_SAT", "qpf_source": "STORMLAB"},
}

stream_sat_ensemble_size = 10                 # 2 laptop / 10 default
stormlab_ensemble_size = 5
ef5_max_workers = 1                           # 1 = sequential EF5 (safest)
dry_run_hours = 6
warmup_enabled = False                        # hindcast training: states already shipped
fim_enabled = True                            # 30m + after forecast only
```

30 m control template: `EF5_conf/templates/ef5_Comoros_30m_control_template.txt`

FIM: unzip stores once with `python fim_store/unzip_stores.py`. See [README_FIM.md](README_FIM.md).

---

## Apptainer / HPC

```sh
TITO_RUNTIME=apptainer ./tito-run.sh hindcast \
    "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros --offline
```

Uses `tito.sif` + **local** `EF5/bin/ef5` (no nested Apptainer). Needs `libtiff`/`libgeotiff`/`libgomp` inside the TITO image (already in the current Dockerfile). Exit **127** usually means a missing shared library — rebuild TITO image.

Convert a Docker archive on HPC: `./docker-to-apptainer.sh`.

---

## Reset after a crash

If a run dies mid-way (OOM, bad GeoTIFFs, half-written states, leftover precip), **reset TITO to the original training snapshot** before retrying **2024-04-27 00:00**:

| OS | Command |
|----|---------|
| Linux / macOS | `./reset_tito.sh` |
| Preview only | `./reset_tito.sh --dry-run` |
| Windows CMD | `reset_tito.cmd` |
| Windows preview | `reset_tito.cmd --dry-run` |

**What it does**

- Wipes contents of `outputs/`, `EF5_conf/precip/`, `EF5_conf/precipEF5/`, `EF5_conf/qpf_store/`
- Wipes STREAM-Sat / StormLab runtime output folders
- **Keeps** state GeoTIFFs for the training warmup **2024-04-26 23:00** (`20240426_2300` and common spellings); deletes other `*.tif` under `EF5_conf/states/`
- Never deletes state **folders**
- If no 23:00 warmup tifs are found, it **refuses** to delete any state tifs (unless `--force`)

Then re-run the training hindcast (add `--offline` if you do not want downloads):

```sh
./tito-run.sh hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros --offline
```

```bat
tito-run.cmd hindcast "2024-04-27 00:00" "2024-04-27 00:00" --regions Comoros --offline
```

`offline_precips/` is **not** wiped — the next `--offline` run restages precip from that archive.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| `docker load` 502 | Docker Desktop not ready — restart daemon |
| EF5 exit **137** | OOM — lower ensembles, `ef5_max_workers=1`, raise Docker RAM |
| EF5 exit **127** | Missing `libtiff.so.5` (local EF5) — rebuild TITO image |
| `Cannot open TIFF` after STREAM-Sat | Corrupt GeoTIFFs from RAM pressure — delete `EF5_conf/precip/stream_sat` and re-run |
| FIM `no_runs` | Wrong chain vs folders — check `outputs/<cycle>/<rkey>/stormlab/` |
| Offline refused cycle | Only 27 Apr 2024 00:00 UTC is allowed |
| Offline still downloads | Old Apptainer path; current launcher prints `Offline : YES` and `OFFLINE precip (hard guard…)` |

---

## References

- Li, Z., et al. (2023). STREAM-Sat / satellite QPE ensemble. *Water Resources Research*.  
- Hartke, S., et al. (2022). Related satellite precipitation ensemble work.  
- Liu, G., Wright, D. B., & Lorenz, D. (2024). StormLab.  
- Peng, B., et al. (2025). StormLab / GEFS applications.  
- EF5: [AHWALab/EF5-builder-toolkit](https://github.com/AHWALab/EF5-builder-toolkit)

---

## Contact

Naman Mehta — naman-mehta@uiowa.edu  
Vanessa Robledo — vanessa-robledodelgado@uiowa.edu  
AHWA Laboratory — [ahwa.lab.uiowa.edu](https://ahwa.lab.uiowa.edu/) — engr-ahwa-lab@uiowa.edu

## Cite

Robledo Delgado, V., & Vergara, H. (2025). Threading Inputs to Outputs (TITO) (v2.0.0). Zenodo. https://doi.org/10.5281/zenodo.17246491
