# Sherpa Documentation

Docs for Sherpa

## Build

```
docker build -t sherpa-docs .
```

## Run

```
docker run --name sherpa-docs --rm -it -p 8000:8000 -v ${PWD}:/docs sherpa-docs
```
