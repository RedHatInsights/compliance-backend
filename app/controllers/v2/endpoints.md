# APIv2 endpoints

## Benchmarks

### `GET /benchmarks` - returns list of benchmarks
```json
{
  "data": [
    {
      "id": "01eef473-8b7a-4dec-bcb4-83e6922bf353",
      "type": "benchmark",
      "attributes": {
        "ref_id": "xccdf_org.ssgproject.content_benchmark_RHEL-7",
        "title": "Guide to the Secure Configuration of Red Hat Enterprise Linux 7",
        "version": "0.1.43",
        "description": "Some description",
        "os_major_version": "7",
        "latest_supported_os_minor_version":[
          "7"
        ],

        "canonical_profiles": [
          {
            "id": "331ee972-66a4-45a1-baf4-d4ddb577295c",
            "type": "profile",
            "attributes": {
              "ref_id": "xccdf_org.ssgproject.content_profile_stig-rhel6-server-upstream",
              "score": 0.0,
              "parent_profile_id": null,
              "external": false,
              "compliance_threshold": 100.0,
              "os_major_version": "6",
              "os_version": "6",
              "policy_profile_id": null,
              "os_minor_version": "",
              "parent_profile_ref_id": null,
              "name": "Upstream STIG for Red Hat Enterprise Linux 6 Server",
              "description": "Profile description",
              "canonical": true,
              "tailored": false,
              "total_host_count": 0,
              "ssg_version": "0.1.28",
              "compliant_host_count": 0,
              "test_result_host_count": 0,
              "unsupported_host_count": 0,
              "business_objective": null,
              "policy_type": "Upstream STIG for Red Hat Enterprise Linux 6 Server",
              "rules": [
                {
                  "id": "00013fff-191c-48d9-87e5-1483af035127",
                  "type": "rule",
                  "attributes": {
                    "ref_id": "xccdf_org.ssgproject.content_rule_audit_rules_file_deletion_events",
                    "remediation_issue_id": "c0f7301e-08b7-4a0a-97fc-d59580a66e8f",
                    "title": "Ensure auditd Collects File Deletion Events by User",
                    "rationale": "Some Rationale",
                    "description": "A rule description",
                    "severity": "medium",
                    "slug": "xccdf_org-ssgproject-content_rule_audit_rules_file_deletion_events-53af87f5-25f3-4222-9511-467c023afc01",
                    "precedence": 983
                  }
                }
              ]
            }
          }
        ]
      }
    }
  ],
  "meta": {
    "total": 22,
    "limit": 20,
    "offset": 1,
  }
}
```
---
### `GET /benchmarks/{id:uuid}` - fetch benchmark detail
```json
{
  "data": {
    "id": "01eef473-8b7a-4dec-bcb4-83e6922bf353",
    "type": "benchmark",
    "attributes": {
      "ref_id": "xccdf_org.ssgproject.content_benchmark_RHEL-7",
      "title": "Guide to the Secure Configuration of Red Hat Enterprise Linux 7",
      "version": "0.1.43",
      "description": "Some description",
      "os_major_version": "7",
      "latest_supported_os_minor_version":[
        "7"
      ],
      "rules": [
        {
          "id": "00013fff-191c-48d9-87e5-1483af035127",
          "type": "rule",
          "attributes": {
            "ref_id": "xccdf_org.ssgproject.content_rule_audit_rules_file_deletion_events",
            "remediation_issue_id": "c0f7301e-08b7-4a0a-97fc-d59580a66e8f",
            "title": "Ensure auditd Collects File Deletion Events by User",
            "rationale": "Some Rationale",
            "description": "A rule description",
            "severity": "medium",
            "slug": "xccdf_org-ssgproject-content_rule_audit_rules_file_deletion_events-53af87f5-25f3-4222-9511-467c023afc01",
            "precedence": 983
          }
        }
      ],
      "canonical_profiles": [
        {
          "id": "331ee972-66a4-45a1-baf4-d4ddb577295c",
          "type": "profile",
          "attributes": {
            "ref_id": "xccdf_org.ssgproject.content_profile_stig-rhel6-server-upstream",
            "score": 0.0,
            "parent_profile_id": null,
            "external": false,
            "compliance_threshold": 100.0,
            "os_major_version": "6",
            "os_version": "6",
            "policy_profile_id": null,
            "os_minor_version": "",
            "parent_profile_ref_id": null,
            "name": "Upstream STIG for Red Hat Enterprise Linux 6 Server",
            "description": "Profile description",
            "canonical": true,
            "tailored": false,
            "total_host_count": 0,
            "ssg_version": "0.1.28",
            "compliant_host_count": 0,
            "test_result_host_count": 0,
            "unsupported_host_count": 0,
            "business_objective": null,
            "policy_type": "Upstream STIG for Red Hat Enterprise Linux 6 Server",
            "rules": [
              {
                "id": "00013fff-191c-48d9-87e5-1483af035127",
                "type": "rule",
                "attributes": {
                  "ref_id": "xccdf_org.ssgproject.content_rule_audit_rules_file_deletion_events",
                  "remediation_issue_id": "c0f7301e-08b7-4a0a-97fc-d59580a66e8f",
                  "title": "Ensure auditd Collects File Deletion Events by User",
                  "rationale": "Some Rationale",
                  "description": "A rule description",
                  "severity": "medium",
                  "slug": "xccdf_org-ssgproject-content_rule_audit_rules_file_deletion_events-53af87f5-25f3-4222-9511-467c023afc01",
                  "precedence": 983
                }
              }
            ]
          }
        }
      ]
    }
  }
}
```
---
### `GET /benchmarks/{id:uuid}/profiles` - profiles for given benchmark
```json
{
  "data": [
    {
      "id": "331ee972-66a4-45a1-baf4-d4ddb577295c",
      "type": "profile",
      "attributes": {
        "ref_id": "xccdf_org.ssgproject.content_profile_stig-rhel6-server-upstream",
        "score": 0.0,
        "parent_profile_id": null,
        "external": false,
        "compliance_threshold": 100.0,
        "os_major_version": "6",
        "os_version": "6",
        "policy_profile_id": null,
        "os_minor_version": "",
        "parent_profile_ref_id": null,
        "name": "Upstream STIG for Red Hat Enterprise Linux 6 Server",
        "description": "Profile description",
        "canonical": true,
        "tailored": false,
        "total_host_count": 0,
        "ssg_version": "0.1.28",
        "compliant_host_count": 0,
        "test_result_host_count": 0,
        "unsupported_host_count": 0,
        "business_objective": null,
        "policy_type": "Upstream STIG for Red Hat Enterprise Linux 6 Server",
        "rules": [
          {
            "id": "00013fff-191c-48d9-87e5-1483af035127",
            "type": "rule",
            "attributes": {
              "ref_id": "xccdf_org.ssgproject.content_rule_audit_rules_file_deletion_events",
              "remediation_issue_id": "c0f7301e-08b7-4a0a-97fc-d59580a66e8f",
              "title": "Ensure auditd Collects File Deletion Events by User",
              "rationale": "Some Rationale",
              "description": "A rule description",
              "severity": "medium",
              "slug": "xccdf_org-ssgproject-content_rule_audit_rules_file_deletion_events-53af87f5-25f3-4222-9511-467c023afc01",
              "precedence": 983
            }
          }
        ]
      }
    },
    {
      //...profile2
    }
  ],
  "meta": {
    "total": 225,
    "search": "canonical=true",
    "limit": 20,
    "offset": 1,
    "sort_by": "score"
  }
}
```
---
### `GET /benchmarks/{id:uuid}/profiles/{id:uuid}` - specific profile from a benchmark
```json
{
  "data": {
    "id": "331ee972-66a4-45a1-baf4-d4ddb577295c",
    "type": "profile",
    "attributes": {
      "ref_id": "xccdf_org.ssgproject.content_profile_stig-rhel6-server-upstream",
      "score": 0.0,
      "parent_profile_id": null,
      "external": false,
      "compliance_threshold": 100.0,
      "os_major_version": "6",
      "os_version": "6",
      "policy_profile_id": null,
      "os_minor_version": "",
      "parent_profile_ref_id": null,
      "name": "Upstream STIG for Red Hat Enterprise Linux 6 Server",
      "description": "Profile description",
      "canonical": true,
      "tailored": false,
      "total_host_count": 0,
      "ssg_version": "0.1.28",
      "compliant_host_count": 0,
      "test_result_host_count": 0,
      "unsupported_host_count": 0,
      "business_objective": null,
      "policy_type": "Upstream STIG for Red Hat Enterprise Linux 6 Server",
      "rules": [
        {
          "id": "00013fff-191c-48d9-87e5-1483af035127",
          "type": "rule",
          "attributes": {
            "ref_id": "xccdf_org.ssgproject.content_rule_audit_rules_file_deletion_events",
            "remediation_issue_id": "c0f7301e-08b7-4a0a-97fc-d59580a66e8f",
            "title": "Ensure auditd Collects File Deletion Events by User",
            "rationale": "Some Rationale",
            "description": "A rule description",
            "severity": "medium",
            "slug": "xccdf_org-ssgproject-content_rule_audit_rules_file_deletion_events-53af87f5-25f3-4222-9511-467c023afc01",
            "precedence": 983
          }
        }
      ]
    }
  }
}
```
---
### `GET /benchmarks/{id:uuid}/rules` - benchmark rules
```json
{
  "data": [
    {
      "id": "00013fff-191c-48d9-87e5-1483af035127",
      "type": "rule",
      "attributes": {
        "ref_id": "xccdf_org.ssgproject.content_rule_audit_rules_file_deletion_events",
        "remediation_issue_id": null,
        "title": "Ensure auditd Collects File Deletion Events by User",
        "rationale": "Rationale",
        "description": "Description",
        "severity": "medium",
        "slug": "xccdf_org-ssgproject-content_rule_audit_rules_file_deletion_events-53af87f5-25f3-4222-9511-467c023afc01",
        "precedence": 983
      }
    },
    {
      //...rule2
    }
  ],
  "meta": {
    "total": 9759,
    "limit": 20,
    "offset": 1,
  }
}
```
---
### `GET /benchmarks/{id:uuid}/rules/{id:uuid}` - specific rule from benchmark
```json
{
  "data": {
    "id": "00013fff-191c-48d9-87e5-1483af035127",
    "type": "rule",
    "attributes": {
      "ref_id": "xccdf_org.ssgproject.content_rule_audit_rules_file_deletion_events",
      "remediation_issue_id": null,
      "title": "Ensure auditd Collects File Deletion Events by User",
      "rationale": "Rationale",
      "description": "Description",
      "severity": "medium",
      "slug": "xccdf_org-ssgproject-content_rule_audit_rules_file_deletion_events-53af87f5-25f3-4222-9511-467c023afc01",
      "precedence": 983
    }
  }
}
```

## Reports

### `GET /reports` - list reports
notes: remodel business objective to be a text field on policy, currently there is new business objective created (id and title) on each edit of the business objective
```json
{
  "data": [
    {
      "id": "2a40fd66-6385-434b-b55e-1f484030f9d2",
      "type": "test_result",
      "attributes": {
        "name": "Example Server Profile",
        "ref_id": "xccdf_org.ssgproject.content_profile_CS2",
        "description": "This prfile is an example of a customized server profile.",
        "policy_type": "Example Server Profile",
        "total_host_count": 12,
        "compliant_host_count": 2,
        "test_result_host_count": 6,
        "unsupported_host_count": 0,
        "os_major_version": "6",
        "compliance_threshold": 97.0,
        "business_objective": "test",
        "ssg_version": "0.1.28",
      },
      "relationships": {
        "policy": {
          "data": {
            "id": "2a40fd66-6385-434b-b55e-1f484030f9d2",
            "name": "Example Server Profile"
          }
        }
      }
    },
    {
      //...test_result2
    }
  ],
  "meta": {
    "total": 20,
    "search": "",
    "limit": 20,
    "offset": 1,
    "sort_by": "score",
    "relationships": true
  },
  "links": {
    "first": "/api/compliance/profiles?limit=20&offset=1&relationships=true&search=canonical%3Dfalse+AND+has_test_results%3Dtrue&sort_by=score",
    "last": "/api/compliance/profiles?limit=20&offset=2&relationships=true&search=canonical%3Dfalse+AND+has_test_results%3Dtrue&sort_by=score",
    "next": "/api/compliance/profiles?limit=20&offset=2&relationships=true&search=canonical%3Dfalse+AND+has_test_results%3Dtrue&sort_by=score"
  }
}
```


