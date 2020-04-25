# escape=`

# To run in isolation mode, make sure you're running Windows 10 Pro or
#   Enterprise and pick the same kernel version for the base image
FROM mcr.microsoft.com/windows/servercore/insider:10.0.19603.1000

ENV chocolateyUseWindowsCompression=false

# Install chocolatey to make our lives easier
RUN powershell -Command iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')); choco feature disable --name showDownloadProgress

# Install dependencies, starting with Microsoft C++ compiler
RUN choco install visualstudio2019-workload-vctools -y

# Install latest Git
RUN choco install git -y

# Install Bazel 1.2.1 and set environment variables that to help Bazel because
#   it can't detect these on this environment on its own
RUN choco install bazel --version=1.2.1 -y
ENV BAZEL_SH C:\tools\msys64\usr\bin\bash.exe
ENV BAZEL_VC "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC"

# Install Python 3.6.8 and pip dependencies, according to
#   https://www.tensorflow.org/install/source_windows
RUN choco install python3 --version=3.6.8 -y
RUN pip3 install six numpy wheel
RUN pip3 install keras_applications==1.0.6 keras_preprocessing==1.0.5 --no-deps

# Install MSYS2, although this will fail on current version of Docker+Windows
RUN choco install msys2 -y
ENV MSYS winsymlinks:nativestrict