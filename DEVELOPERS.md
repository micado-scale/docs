# Introduction #

This document aims to collect the guidelines for the development of MiCADO. This should be treated as an evolving document.

# Coding Style #
 
 - Python: PEP-8 [[4]]
 - YAML: 4 Space indent

# Versioning #
We adapted _semantic versioning 2.0.0_ [[3]]. This infers the following renaming of previous releases:

 - V3 -> 0.3.0 (further modifications will result in 0.3.1, 0.3.2, etc.)
 - V4 -> 0.4.0 

Previous releases (V1 and V2) should remain untouched.

# Repositories #
We should use separate GIT repositories for each separate logical unit within the _micado-scale_ github.com organization as follows: 

1. Each component should be placed in its own repository with the prefix _component-_, e.g., _component-alert\_manager_.
2. The _micado_ repository is the main repository, containing "glue" files (e.g., cloud-init and/or docker-compose related ones).
3. Documentation should go into the _docs_ repository in either markdown or restructured text format.

Each repository should contain a README.md file explaining the purpose of the repository, basic functionality, and pointers for further documentation (in the docs repository).

The master branch of each repository should contain an ISSUE\_TEMPLATE.md for issue reporting. This should be copied over from the master branch of the _micado_ repository.

# Branching #
We adapt the _successful GIT branching method_ [[1]] with the following modifications:
 
 1. The _master_ branch should always represent the latest stable release.
 2. _develop_ branch is for development.
 3. In each repository, from its _develop_ branch, for each major release, a release branch should be created.
 4. Release branches should be named based on their major and minor versions: v_MAJOR_._MINOR_.x  
    - E.g., for the 0.4 releases, the branch should be called _0.4.x_ (x is literal, represents that all 0.4 releases, e.g., 0.4.0, 0.4.1, etc. are based on this branch).

# Releases #
For 0.4.0 and 0.3.0 we should use the following procedures, as 0.4.0 is considered a new implementation, but 0.3.x requires fixes and refactoring.

For the current (0.4.x) release branch:
 1. Merge the release branch to _develop_ in each affected repository.
 2. Merge the release branch to _master_.
 3. Create tag with the release number (e.g., 0.4.0).

For the 0.3.x release branch:
 1. Create a tag on the release branch (no merging with develop branch, but selected fixes can be added).


# Commit Guidelines #
We adopt the _angular.js commit guidelines_ [[2]] with some modifications. We do not pre-define scopes. The scope part should describe the affected part in the commit message. 

# Dev Docker registry #
We use a private docker registry to develop MiCADO components. This registry is running on CloudSigma and protected with basic authentication.

* The address of the registry: _cola-registry.lpds.sztaki.hu_

* To get access, contact with Attila Farkas (attila.farkas@sztaki.mta.hu) at SZTAKI.

* The naming convention in the registry: _username/imagename:version_

* Push image to the registry:
  ```
  docker login cola-registry.lpds.sztaki.hu
  docker push cola-registry.lpds.sztaki.hu/username/imagename:version
  ```

* To use the registry during the development:
  1. Replace the default image name with dev image name
  2. Insert this into the cloud-init file:
     ```
     docker login -u username -p password cola-registry.lpds.sztaki.hu
     ```

* To create docker service with private registry authentication:
  ```
  docker service create --with-registry-auth image_name
  ```

* To create docker stack with private registry authentication:
  ```
  docker stack deploy --with-registry-auth -c docker-compose.yml stack_name
  ```

[1]: http://nvie.com/posts/a-successful-git-branching-model/
[2]: https://github.com/angular/angular.js/blob/master/DEVELOPERS.md#-git-commit-guidelines
[3]: https://semver.org/
[4]: https://www.python.org/dev/peps/pep-0008/
