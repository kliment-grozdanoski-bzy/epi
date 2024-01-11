# template-powerbi-reports

SolidOps.PBI repository template for reports

Confluence page: https://beazley.atlassian.net/wiki/spaces/PDG/pages/2144698862/SolidOps.PBI+and+git

### build.cmd

TeamCity uses the build.cmd script to build.

Options

|  Option | Meaning  |
|---|---|
| -Install | Not implemented: no additional tools required  |
| -Update | Not implemented: no update requirements yet  |
| -Build | Not implemented: no build required due to the nature of *.pbix files |
| -Pack | Create a nuget package based on the src\<respository-name>.nuspec file |
| -Publish | Publish package to deployment artifacts repository |
| -Release | Create Octopus Deploy release |


Example run (create deployment package, publish to deployment artifacts, create deployment release)

```
build.cmd -Pack -Publish -Release
```