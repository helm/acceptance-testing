*** Settings ***
Documentation     Verify helm repo commands work as expected.
...
Library           lib/Sh.py

*** Test Cases ***
No repos provisioned yet
    Sh.Fail  helm repo list
    Sh.Output contains  Error: no repositories

Add a first valid repo
    Sh.Pass  helm repo add gitlab https://charts.gitlab.io
    Sh.Output contains  "gitlab" has been added to your repositories

Add invalid repo without protocol
    Sh.Fail  helm repo add invalid notAValidURL
    Sh.Output contains  Error: could not find protocol handler

Add invalid repo with protocol
    Sh.Fail  helm repo add invalid https://example.com
    Sh.Output contains  Error: looks like "https://example.com" is not a valid chart repository or cannot be reached

Add a second valid repo
    Sh.Pass  helm repo add jfrog https://charts.jfrog.io
    Sh.Output contains  "jfrog" has been added to your repositories

Check output of repo list
    Sh.Pass  helm repo list
    Sh.Output contains  gitlab
    Sh.Output contains  https://charts.gitlab.io
    Sh.Output contains  jfrog
    Sh.Output contains  https://charts.jfrog.io
    Sh.Output does not contain  invalid

Make sure both repos get updated
    Sh.Pass  helm repo update
    Sh.Output contains  Successfully got an update from the "gitlab" chart repository
    Sh.Output contains  Successfully got an update from the "jfrog" chart repository
    Sh.Output contains  Update Complete. ⎈ Happy Helming!⎈

Try to remove inexistant repo
    Sh.Fail  helm repo remove badname
    Sh.Output contains  Error: no repo named "badname" found

Remove a repo
    Sh.Pass  helm repo remove gitlab
    Sh.Output contains  "gitlab" has been removed from your repositories

Make sure repo update will only update the remaining repo
    Sh.Pass  helm repo update
    Sh.Output contains  Successfully got an update from the "jfrog" chart repository
    Sh.Output contains  Update Complete. ⎈ Happy Helming!⎈

Try removing an already removed repo
    Sh.Fail  helm repo remove gitlab
    Sh.Output contains  Error: no repo named "gitlab" found

Remove last repo
    Sh.Pass  helm repo remove jfrog
    Sh.Output contains  "jfrog" has been removed from your repositories

Check there are no more repos
    Sh.Fail  helm repo list
    Sh.Output contains  Error: no repositories to show

Make sure repo update now fails, with a proper message
    Sh.Fail  helm repo update
    Sh.Output contains  Error: no repositories found. You must add one before updating

# "helm repo index" should also be tested
