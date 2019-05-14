#!/usr/bin/env bash
# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

ensure-in-gopath() {
  fake_gopath=$(mktemp -d --tmpdir codegen.gopath.XXXX)
  trap 'rm -rf "$fake_gopath"' EXIT

  fake_repopath=$fake_gopath/src/k8s.io/test-infra
  mkdir -p "$(dirname "$fake_repopath")"
  ln -s "$repo_root" "$fake_repopath"

  export GOPATH=$fake_gopath
  cd "$fake_repopath"
}

codegen-init() {
  echo "Ensuring generators exist..." >&2
  go install ./vendor/k8s.io/code-generator/cmd/{deepcopy,client,lister,informer}-gen
  export GOPATH="${GOPATH:-$HOME/go}"
  export PATH="${GOPATH}/bin:${PATH}"
}


gen-deepcopy() {
  echo "Generating DeepCopy() methods..." >&2
  deepcopy-gen \
    --go-header-file hack/boilerplate/boilerplate.generated.go.txt \
    --input-dirs k8s.io/test-infra/prow/apis/prowjobs/v1 \
    --output-file-base zz_generated.deepcopy \
    --bounding-dirs k8s.io/test-infra/prow/apis
}

gen-client() {
  echo "Generating client..." >&2
  client-gen \
    --go-header-file hack/boilerplate/boilerplate.generated.go.txt \
    --clientset-name versioned \
    --input-base "" \
    --input k8s.io/test-infra/prow/apis/prowjobs/v1 \
    --output-package k8s.io/test-infra/prow/client/clientset
}

gen-lister() {
  echo "Generating lister..." >&2
  lister-gen \
    --go-header-file hack/boilerplate/boilerplate.generated.go.txt \
    --input-dirs k8s.io/test-infra/prow/apis/prowjobs/v1 \
    --output-package k8s.io/test-infra/prow/client/listers
}

gen-informer() {
  echo "Generating informer..." >&2
  informer-gen \
    --go-header-file hack/boilerplate/boilerplate.generated.go.txt \
    --input-dirs k8s.io/test-infra/prow/apis/prowjobs/v1 \
    --versioned-clientset-package k8s.io/test-infra/prow/client/clientset/versioned \
    --listers-package k8s.io/test-infra/prow/client/listers \
    --output-package k8s.io/test-infra/prow/client/informers
}

export GO111MODULE=on
codegen-init
ensure-in-gopath
export GO111MODULE=off
gen-deepcopy
gen-client
gen-lister
gen-informer
