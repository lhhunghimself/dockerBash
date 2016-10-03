# dockerBash
Simple wrapper that allows bash-like syntax for docker container workflows

#TL;DR

dockerBash is a dockerized Perl script that wraps containers to use simple unix pipes and redirect notation to allow definition of pipelines in a familiar UNIX style.

For example:
```bash
docker::dbash -c 'docker::cat < /tmp/myFile | docker::wc -c'
```
is the equivalent of
```bash
bash -c 'cat < /tmp/myFile | wc -c'
```
except that docker containers are called instead of the local binaries. The docker version does not require bash to be on the client and any container can be used.

##Installation

```bash
cd <PATH>/dockerBash
```
Build the dbash container
```bash
sudo docker build -t "dbash" dbash
```
Edit path in installAliases.sh with vi or nano
installAliases.sh installs the dbash script locally and aliases the run dbash command to docker::dbash
```bash
installAliases.sh 
```
To test build the test containers:
Edit path in buildSimpleDockerfile.sh with vi or nano
```bash
docker::dbash -t <PATH>/dockerBash/buildSimpleContainers.dsh
docker::dbash -t <PATH>/dockerBash/simpleTests.dsh
```
##Supported flags
  -v[erbose]
  
  -c[ommand]  <command_string> (can be more than one instance)
  
  -l[ocal]    use local copy of dbash
  
  -t[ext]     script file (can be more than one instance)
