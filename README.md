# Gravitational wave sample generation code

This repository includes additional features to the gravitational wave sample generation code by Timothy Gebhard and Niki Kilbertus for [generating realistic synthetic gravitational-wave data.](https://github.com/timothygebhard/ggwd/)

The scripts in this repository are built on the basis of the [PyCBC software package](https://pycbc.org/), with the intention of providing an easy to use method for generating synthetic gravitational-wave samples in real and synthetic gaussian detector noise.

In order to generate samples, run:

```
python generate_sample.py --n-noise-realizations=1
```
To generate a specific number of noise realizations for a particular waveform, replace ```--n-noise-realizations=1``` with the desired number of noise realizations.
