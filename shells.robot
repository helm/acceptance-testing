# Copyright (C) 2019 Ville de Montreal
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

*** Settings ***
Documentation     Verify Helm functionality on multiple shells.
...
...               Docker containers will be created for each of the shells
...               versions being tested on Linux.
...               Tests on MacOS will be run if the host running the tests
...               is MacOS and has the necessary setup (bash completion and/or zsh)
...
Library           lib/Completion.py

*** Test Cases ***
Helm shell completion works
    Completion.Run all completion tests
