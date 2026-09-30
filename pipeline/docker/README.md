To run docker desktop, use the following command: 

```
docker run --rm -it \
  -v "$(pwd)/license.txt":/usr/local/freesurfer/license.txt \
  -v /Users/chblaine/Documents/R61:/data \
  multiecho_pipeline:v3 \
  bash

```
First paste is freesurfer license. 
Second paste is where your R61 or study folder is located.


# Building

Build docker, cd ./pipeline/docker :
```

docker build --no-cache -f ./docker/Dockerfile -t multiecho_pipeline:v3 ./

```
