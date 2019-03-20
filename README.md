# Response Simulation

A collection of scripts to help with simulating the response of structures.

## What is it?

This repository contains scripts to create finite element models and simulate the response of structures to various loading conditions. My objective is to collect the scripts that I believe others might be able to use for their work and share them with the community. 

I work with OpenSees, so the scripts are Tcl files that can be used in the Tcl interpreter of OpenSees. I share 24 BRBF models in this initial commit, coupled with the FEMA P695 Far Field ground motion record set and two examples to perform either dynamic response history or pushover analysis on any of the shared models. 

## What can I use it for?

You can take advantage of these files in multiple ways:

- Download all files and run dynamic BRBF response simulation within minutes. Tailor the examples to fit your research methodology, or perhaps change the set of ground motions used.
- Connect all of the above to a more advanced workflow that you already have in Python, MATLAB, or another programming language and control the analyses from there.
- Use or extend the modeling and analysis routines in the `core` and the `examples` folders only. Create your own BRBF or other frame model input files. 
- Share your existing models with the community to get exposure and help others.

## Why should I use it?

1. The files are free.
2. It is more efficient to use and edit these files than to write your own frame model from scratch.
3. This is a step towards a collection of models that are tested, vetted, and supported by the engineering community.

## Requirements

The files were tested with OpenSees 2.5.0.

## License

The files are distributed under the BSD 3-Clause license, see LICENSE

## Citing

Currently, all files originate from the same research. When models from various sources are added in the future, the corresponding publication will be identified for each of them.

If you use the files in the repository, please cite them as being from the following work:

Á. Zsarnóczay, L.G. Vigh, Eurocode conforming design of BRBF - Part II: Design procedure evaluation, Journal of Constructional Steel Research, 135:253-264, 2017, doi: [10.1016/j.jcsr.2017.04.013](https://doi.org/10.1016/j.jcsr.2017.04.013)

## Contact

Adam Zsarnóczay, Stanford University, adamzs@stanford.edu