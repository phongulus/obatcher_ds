# Batch Parallel Data Structures with Obatcher

This is the repository for various case studies of batch parallel data structures with OBatcher (https://github.com/verse-lab/obatcher).

As this requires a custom version of the library `domainslib` for Multicore OCaml, it is advisable that you create a new `opam` switch to run this.

## Build instructions

First, set up OBatcher along with a new `opam` switch in a separate directory:

```
opam switch create obatcher_test ocaml-base-compiler.5.0.0
opam install dune batteries progress ptime cmdliner
eval $(opam env)
git clone https://github.com/verse-lab/obatcher.git obatcher
cd obatcher
opam pin add domainslib file://`pwd`
```

Note: for VSCode users, you will want to run the following as well to reinstall the prerequisites for the OCaml Platform extension in the new switch:

```
opam install ocamlformat ocaml-language-server
```

Exit the OBatcher directory. You can now clone and build the code in this repository.

```
git clone https://github.com/phongulus/obatcher_ds.git obatcher_ds
cd obatcher_ds
dune build
```

## Running tests and benchmarks

Provided tests can be simply run after building with:

```
dune runtest
```

For benchmarking, navigate to the `benchmark/` directory and use `make` commands:

```
cd benchmark
make avltree_batched
```

See the Makefile for the full list of benchmarks that can be run this way. A more advisable way to run the benchmarks would be to use the provided Jupyter Notebook. It is recommended to set up a Python virtual environment for this purpose:

```
python -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
```

When running the Jupyter Notebook, use the virtual environment set up above.

## Adding more data structures

TODO.