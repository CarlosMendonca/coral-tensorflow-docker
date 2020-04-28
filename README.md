This Dockerfile is a WIP attempt to set up a minimal environment to compile TensorFlow Lite as a DLL library to use it on Google Coral development on Windows with C++. Currently, this requires some manual steps, but it works.

# Host

Clone this repo and build the Docker image:
```
docker build -t tf:latest .
```

If docker hangs after installing MSYS2 (should be one of the last steps), it's because [this bug](https://github.com/microsoft/hcsshim/issues/696) hasn't been fixed yet. The workaround is to run docker-ci-zap on a new PS terminal with Admin privileges. Try removing all folders starting with hcs until the docker process "un-hangs":

```
.\docker-ci-zap.exe -folder C:\ProgramData\Docker\tmp\hcsNNNNNNNNN
```

Create and run the container in interactive mode:
```
docker run -it tf:latest
```

Alternatively, if you modified the Dockerfile to match the container kernel version with the host kernel version, run it as:
```
docker run -it tf:latest --isolation=process
```

If the container already exists, find its id and start it with:
```
docker container ls -a
docker start -ai tf:latest
```

# Container

Configure the MSYS2 environemnt:
```
C:\tools\msys64\msys2_shell.cmd -defterm -no-start -here -c "pacman -Sy zip unzip patch tar diffutils git nano"
```

Configure git to be able to cherry-pick later:
```
git config --global user.name "John Doe"
git config --global user.email "john@isp.com"
```

Clone TensorFlow:
```
cd source
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
```

Take the code to the appropriate commit to align it with the edgetpu.dll runtime and cherry-pick some necessary changes:
```
git checkout d855adfc5a0195788bf5f92c3c7352e638aa1109
git cherry-pick e8376142f50982e2bc22fae2d62f8fcfc6e88df7
git cherry-pick 72cd947f231950d7ecd1406b5a67388fef7133ea
```

Run download_dependecies.sh script from MSYS2:
```
C:\tools\msys64\msys2_shell.cmd -defterm -no-start -here -c "./tensorflow/lite/tools/make/download_dependencies.sh"
```

Modify the Bazel script:
```
###
# --- a/tensorflow/lite/build_def.bzl
# +++ b/tensorflow/lite/build_def.bzl
# @@ -159,6 +159,7 @@ def tflite_cc_shared_object(
#      tf_cc_shared_object(
#          name = name,
#          copts = copts,
# +        features = ["windows_export_all_symbols"],
#          linkstatic = linkstatic,
#          linkopts = linkopts + tflite_jni_linkopts(),
#          framework_so = [],
###
```

Configure the environment:
```
python configure.py
bazel build -c opt //tensorflow/lite:tensorflowlite
```

# Host

Back on the host, if compilation worked:
```
docker cp  <CONTAINER_ID>:C:\tensorflow\bazel-bin.bkp\tensorflow\lite\tensorflowlite.dll .
docker cp  <CONTAINER_ID>:C:\tensorflow\bazel-bin.bkp\tensorflow\lite\tensorflowlite.dll.if.lib .
```

# Acknowledgements

- https://github.com/google-coral/edgetpu/issues/44#issuecomment-589170013
- https://github.com/iwatake2222/EdgeTPU_CPP
