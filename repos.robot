*** Settings ***
Documentation     Verify helm repo commands work as expected.
...
Library           lib/Sh.py

*** Test Cases ***
No repos provisioned yet
    Should Fail  helm repo list
    Output contains  Error: no repositories

Add a first valid repo
    Should Pass  helm repo add gitlab https://charts.gitlab.io
    Output contains  "gitlab" has been added to your repositories

Add invalid repo without protocol
    Should Fail  helm repo add invalid notAValidURL
    Output contains  Error: could not find protocol handler

Add invalid repo with protocol
    Should Fail  helm repo add invalid https://example.com
    Output contains  Error: looks like "https://example.com" is not a valid chart repository or cannot be reached

Add a second valid repo
    Should Pass  helm repo add jfrog https://charts.jfrog.io
    Output contains  "jfrog" has been added to your repositories

Check output of repo list
    Should Pass  helm repo list
    Output contains  gitlab
    Output contains  https://charts.gitlab.io
    Output contains  jfrog
    Output contains  https://charts.jfrog.io
    Output does not contain  invalid

Make sure both repos get updated
    Should Pass  helm repo update
    Output contains  Successfully got an update from the "gitlab" chart repository
    Output contains  Successfully got an update from the "jfrog" chart repository
    Output contains  Update Complete. ⎈ Happy Helming!⎈

Try to remove inexistant repo
    Should Fail  helm repo remove badname
    Output contains  Error: no repo named "badname" found

Remove a repo
    Should Pass  helm repo remove gitlab
    Output contains  "gitlab" has been removed from your repositories

Make sure repo update will only update the remaining repo
    Should Pass  helm repo update
    Output contains  Successfully got an update from the "jfrog" chart repository
    Output contains  Update Complete. ⎈ Happy Helming!⎈

Try removing an already removed repo
    Should Fail  helm repo remove gitlab
    Output contains  Error: no repo named "gitlab" found

Remove last repo
    Should Pass  helm repo remove jfrog
    Output contains  "jfrog" has been removed from your repositories

Check there are no more repos
    Should Fail  helm repo list
    Output contains  Error: no repositories to show

Make sure repo update now fails, with a proper message
    Should Fail  helm repo update
    Output contains  Error: no repositories found. You must add one before updating

# "helm repo index" should also be tested
