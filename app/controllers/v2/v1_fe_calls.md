# calls.md

Backend calls for FE workflows based on [this document](https://docs.google.com/document/d/1KEhXZ5g9QiadDvw1aWZzz-Og5ASQNjHqcJNTPWydhPQ/edit?usp=sharing)

## Policies

### View policies
List policies
```
query:
  profiles(external = false and canonical = false)
```
Delete Policy
```
mutation:
  deleteProfile({id})
query:
  profiles(external = false and canonical = false)
```
### Create new policy
Select OS and policy type
```
query supportedProfilesByOSMajor:
  osMajorVersions,
  profiles(search: "external = false and canonical = false")
```
Details
--
Select systems
```
/inventory/v1/system_profile/operating_system
query:
  systems
    - name
    - tags
    - operatingSystem
```
Tailor Rules
```
query:
  benchmarks(filter)
query:
  profiles(id)
query:
  benchmark(id)
```
Save
```
mutation:
  createProfile(input: object)
mutation:
  associateSystems({id, systemIds})
mutation:
  associateRules({id, ruleRefIds})
```
### View Single Policy
**Details Tab**
View Details
```
query Profile(id):
  profile(id)
```
Edit Threshold
```
mutation:
  updateProfile({complianceThreshold, description, profileId, name})
mutation:
  associateSystems({id, [systemId]}})
query:
  profile({policyId})
```
Edit Business Objective
```
mutation:
  createBusinessObjective({title})
mutation:
  updateProfile({id, name, description, complianceThreshold, businessObjectiveId})
mutation:
  associateSystems({id, [systemsId]})
query:
  profile(policyId)
```
Edit Description
```
mutation:
  updateProfile({complianceThreshold, description, profileId, name})
mutation:
  associateSystems({id, [systemId]}})
query:
  profile({policyId})
```
**Rules Tab**
View rules
```
query:
  profile(policyId)
```
View different OS minor version
```
query:
  profile(policyId)
```
Edit rules
- initial load:
  ```
  query:
    profile(policyId)
  query:
    systems
  query:
    benchmarks
  /api/inventory/v1/system_profile/operating_system
  query:
    systems         //systems table query
  query:            //one for each SSG version
    benchmark(id)
  ```
- edit and save
  ```
  mutation:
    updateProfile({id, name, description, complianceThreshold, businessObjectiveId})
  mutation:
    associateSystems({id, [systemId]}})
  mutation:         //multiple calls for different ids (?)
    assiciateRules({id, [ruleRefId]})
  ```
**Systems Tab**
Initial load
```
query:
  getSystems(filter: policyId = id)
query:
  profile(policyId)
/api/inventory/v1/system_profile/operating_system
query:
  systems         //systems table query
```
Edit Systems
- initial load
  ```
  query:
    profile(policyId)
  query:
    systems
  query:
    benchmarks
  query:          //for each SSG
    benchmark(id)
  query:
  /api/inventory/v1/system_profile/operating_system
  query:
    systems         //systems table query
  ```
- edit save
  ```
  mutation:
    updateProfile({id, name, description, complianceThreshold, businessObjectiveId})
  mutation:
    associateSystems({id, [systemId]}})
  mutation:         //multiple calls for different ids (?)
    assiciateRules({id, [ruleRefId]})
  ```

## Reports
### View reports
List all reports
```
query:
  profiles(has_policy_test_results = true AND external = false)
```
### Report Detail
View report
```
query:
  profile(policyId)
/api/inventory/v1/system_profile/operating_system
query:
  systems         //systems table query
/api/inventory/v1/tags
```
Export to PDF
```
/api/compliance/supported_ssgs
query:
  systems
query:
  profiles(filter: policyId = id)
```

## Systems
### View Systems
List all compliance systems
```
/api/inventory/v1/system_profile/operating_system
query:
  systems         //systems table query
/api/inventory/v1/tags
```
### System Detail
Show system detail
```
query:
  system(id)
```


