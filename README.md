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
- Two node types, mapped directly to this cluster's Slurm partitions:
  - **CPU** (`c` partition) — 18 nodes, 96 cores, ~755 GB RAM each
  - **GPU** (`g` partition) — 8 nodes, 192 cores, ~1.5 TB RAM, 4x NVIDIA B200 each
- GPU count selector (0-4 per node), requested via `gpus_per_node: nvidia_b200:N`
- Root directory selector for the Jupyter session
- Module-based software loading via Lmod (EESSI software stack)

## Requirements

### Compute Node Software

This Batch Connect app requires the following on the **compute nodes** (`c`
and `g` partitions), not the OnDemand node itself:

- [Lmod](https://www.tacc.utexas.edu/research-development/tacc-projects/lmod)
- A `JupyterLab/<version>` module (used for Lab mode) and a matching
  `JupyterNotebook/<version>` module (used for Notebook mode — the
  `JupyterLab` module on this stack does not bundle the classic `notebook`
  package). Both are provided by the EESSI software stack. See the mapping in
  `template/script.sh.erb` if a new `jupyter_version` is added to `form.yml`.
- [OpenSSL](https://www.openssl.org/) (used to hash the Jupyter server password)

### Open OnDemand

- Slurm scheduler

## Configuration

### form.yml attributes

| Attribute         | Widget          | Description                                              | Default   |
|-------------------|-----------------|------------------------------------------------------------|-----------|
| `cluster`         | (fixed)         | Target cluster                                              | `cbe`     |
| `mode`            | radio           | Jupyter Lab (`1`) or Jupyter Notebook (`0`)                 | `1` (Lab) |
| `working_dir`     | path_selector   | Root directory for the Jupyter session                      | `$HOME`   |
| `bc_num_hours`    | number          | Maximum wall time (hours)                                   | `1`       |
| `node_type`       | select          | `cpu` (`c` partition) or `gpu` (`g` partition)               | `cpu`     |
| `gpus`            | number_field    | Number of NVIDIA B200 GPUs to request (0-4, `gpu` node type only) | `0`  |
| `num_cores`       | number_field    | Number of CPU cores (1-96 on `cpu`, 1-192 on `gpu`)          | `1`       |
| `jupyter_version` | select          | JupyterLab version to launch                                 | `4.4.9-GCCcore-14.3.0` |

Adding a new `jupyter_version` option requires a matching entry in the
`notebook_module_for` lookup in `template/script.sh.erb`, since the Lab and
Notebook modules are versioned independently on this software stack.

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
