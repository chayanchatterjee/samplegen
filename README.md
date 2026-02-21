# Gravitational wave sample generation code

This repository includes additional features to the gravitational wave sample generation code by Timothy Gebhard and Niki Kilbertus for [generating realistic synthetic gravitational-wave data.](https://github.com/timothygebhard/ggwd/)

The scripts in this repository are built on the basis of the [PyCBC software package](https://pycbc.org/), with the intention of providing an easy to use method for generating synthetic gravitational-wave samples in real and synthetic gaussian detector noise.

In order to generate samples, run:

```
python generate_sample.py --n-noise-realizations=1
```
To generate a specific number of noise realizations for a particular waveform, replace ```--n-noise-realizations=1``` with the desired number of noise realizations.


## pSEOBNR generation workflow

To generate samples with `SEOBNRv5PHM` while keeping the rest of the sample-generation pipeline identical (noise injection, whitening, filtering), use the dedicated config:

```bash
python generate_sample.py --config-file default_pSEOBNR.json
```

You can pass non-GR deviation parameters for individual higher-order modes directly from the command line:

```bash
python generate_sample.py --config-file default_pSEOBNR.json \
  --domega-22 0.2 --dtau-22 0.1 \
  --domega-33 0.2 --dtau-33 0.1 \
  --domega-21 0.0 --dtau-21 0.0
```

The waveform parameter file `config_files/waveform_params_pSEOBNR.ini` is configured to sample intrinsic parameters from an HDF file via `fromfile`; update the `filename` / `dataset` entries for your posterior file layout.
