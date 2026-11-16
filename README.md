# Batch Connect - Jupyter (CBE)

## Overview

An [Open OnDemand](https://openondemand.org/) Batch Connect app that launches a [Jupyter](https://jupyter.org/) server (Lab or classic Notebook) as an interactive session on the CBE Slurm cluster. This app is a site-specific fork of OSC's [`bc_osc_jupyter`](https://github.com/OSC/bc_osc_jupyter), trimmed down to target only this cluster.

- **Upstream project:** [Jupyter](https://jupyter.org/)
- **Batch Connect template:** `basic`
- **Scheduler:** Slurm
- **Cluster:** `cbe`

## Screenshots

![Jupyter running in browser](docs/bc_osc_jupyter.png)

## Features

- Launches either Jupyter Lab or Jupyter Notebook (user-selectable radio button)
- **Jupyter version** select, populated from the site's module snapshot
  (`/etc/ood/modules/cbe.json`, newest first), with a built-in list of known
  modules if the snapshot can't be read
- **Additional Python bundle** select (`SciPy-bundle`), filtered in the browser
  (`form.js`) to the bundles of the same toolchain generation as the chosen
  Jupyter version, so its packages are importable in the default kernel
- Partition select: **CPU** (`c`), **GPU** (`g`, one GPU of the chosen type:
  B200, B200 MIG slice, A100, A100 MIG slice, Quadro RTX 6000 or any), and
  **High memory** (`m`, at least 200 GB)
- CPU cores and memory selects; memory sizes are filtered per partition
- Wall time choices read from the `interactive` QOS (`qos_limits.rb`) and
  checked again at submit time
- Root directory selector and extra Jupyter command-line arguments
- [`jupyterlmod`](https://github.com/cmd-ntrf/jupyter-lmod) is loaded with the
  same GCCcore as the Jupyter module: its "Softwares" sidebar panel lets users
  load further modules in the session; they reach a notebook after
  Kernel → Restart Kernel. (A small kernel-manager override in the generated
  `config.py`, see `template/before.sh.erb`, makes restarts pick up the
  server's current environment; stock Jupyter keeps the environment from when
  the notebook's kernel was first created.) If no matching build exists, the session starts
  without it.
- Selected modules are re-validated when the job script is rendered, and
  their availability is checked on the compute node itself (falling back to
  another build of the same toolchain if the selected one is missing there)

## Requirements

### Compute Node Software

This Batch Connect app requires the following on the **compute nodes** (`c`
and `g` partitions), not the OnDemand node itself:

- [Lmod](https://www.tacc.utexas.edu/research-development/tacc-projects/lmod)
- A `JupyterLab/<version>` module (used for Lab mode) and a matching
  `JupyterNotebook/<version>` module with the same GCCcore version (used for
  Notebook mode — the `JupyterLab` module on this stack does not bundle the
  classic `notebook` package). Both are provided by the EESSI software stack.
- [OpenSSL](https://www.openssl.org/) (used to hash the Jupyter server password)

### Open OnDemand

- Slurm scheduler

## Configuration

### Files

| File | Purpose |
|------|---------|
| `form.yml.erb` | The form (pinned to cluster `cbe`) |
| `form.js` | Bundle filtering, memory filtering per partition, GPU type visibility |
| `submit.yml.erb` | Slurm options: partition, memory, cores, GPU, QOS wall-time check |
| `qos_limits.rb` | Reads the `interactive` QOS limits with `sacctmgr` |
| `template/jupyter_modules.rb` | Module discovery and compatibility rules, shared by the form and the job script |
| `orion_form.yml`, `orion_submit.yml.erb` | Older form/submit used on orion |

### form attributes

| Attribute              | Widget        | Description                                               | Default |
|------------------------|---------------|-----------------------------------------------------------|---------|
| `jupyter_module`       | select        | JupyterLab module to launch                               | newest  |
| `mode`                 | radio         | Jupyter Lab (`1`) or Jupyter Notebook (`0`)               | `1` (Lab) |
| `python_bundle_module` | select        | Optional `SciPy-bundle` module of the same toolchain      | None    |
| `extra_jupyter_args`   | text_field    | Arguments appended to the `jupyter` command               | empty   |
| `working_dir`          | path_selector | Root directory for the Jupyter session                    | `$HOME` |
| `partition`            | select        | `c`, `g` or `m`                                           | `c`     |
| `gpu_type`             | select        | GRES type for the one GPU on `g` (hidden elsewhere)       | B200 MIG slice |
| `cores`                | select        | CPU cores (`--cpus-per-task`)                             | `1`     |
| `ram`                  | select        | Memory in GB (`c`/`g`: 4-128, `m`: 200-1000)              | `4`     |
| `bc_num_hours`         | select        | Wall time, up to the `interactive` QOS limit              | `1`     |

A new toolchain generation (e.g. GCCcore 15.2.0 → 2026a) needs a line in
`GENERATIONS` in `template/jupyter_modules.rb` for its bundles to be offered.
Update `FALLBACK` there when the installed modules change.

## Troubleshooting

Always check the `/output` directory of the session data for the job. This
can be accessed by clicking the session id within the session card. Within
this directory, `output.log` shows output from the job as it started, and
any logging introduced in the app's scripts under `template/`.

It can be helpful to add extra logging into `template/*.sh.erb` while
troubleshooting connection issues.

## References

- [Jupyter](https://jupyter.org/) — the application launched by this app
- [Open OnDemand](https://openondemand.org/) — the HPC portal framework
- [OOD Batch Connect app development docs](https://osc.github.io/ood-documentation/latest/app-development.html)
- [Changelog](CHANGELOG.md) — upstream `bc_osc_jupyter` release history prior to this fork

## License

- Code is licensed under MIT (see `LICENSE.txt`); original copyright Ohio
  Supercomputer Center.
- The Jupyter logo is a trademark of the NumFOCUS foundation.

## Acknowledgments

Forked from [`bc_osc_jupyter`](https://github.com/OSC/bc_osc_jupyter),
built on [Open OnDemand](https://openondemand.org/), developed by the
[Ohio Supercomputer Center (OSC)](https://www.osc.edu/).
