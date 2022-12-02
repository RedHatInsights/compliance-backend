# APIv2 endpoints

## Ssgs

### `GET /ssgs` - returns list of ssgs
```json
{
  "data": [
    {
      "id": "01eef473-8b7a-4dec-bcb4-83e6922bf353",
      "type": "ssg",
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
### `GET /ssgs/{id:uuid}` - fetch ssg detail
```json
{
  "data": {
    "id": "01eef473-8b7a-4dec-bcb4-83e6922bf353",
    "type": "ssg",
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
### `GET /ssgs/{id:uuid}/profiles` - profiles for given ssg
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
### `GET /ssgs/{id:uuid}/profiles/{id:uuid}` - specific profile from a benchmark
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
### `GET /ssgs/{id:uuid}/rules` - benchmark rules
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
### `GET /ssgs/{id:uuid}/rules/{id:uuid}` - specific rule from benchmark
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

## Systems

### `GET /systems` - list systems
```json
{
  "data": [
    {
      "id": "54322ed4-3ccc-4ad7-8acb-749d1878e112",
      "type": "host",
      "attributes": {
        "name": "ortiz.name",
        "os_major_version": 8,
        "os_minor_version": 6,
        "last_scanned": "Never",
        "rules_passed": 0,
        "rules_failed": 0,
        "has_policy": true,
        "culled_timestamp": "2032-11-04T14:14:30Z",
        "stale_timestamp": "2032-10-21T14:14:30Z",
        "stale_warning_timestamp": "2032-10-28T14:14:30Z",
        "updated": "2022-10-21T14:14:30Z",
        "insights_id": "9a3acaf0-3378-013b-ca1f-1ab2effbf581",
        "compliant": true
      }
    },
    {
      //...system2
    }
  ],
  "meta": {
    "total": 60,
    "search": "has_test_results=true or has_policy=true",
    "tags": [],
    "limit": 20,
    "offset": 1,
    "relationships": true
  },
  "links": {
    "first": "/api/compliance/systems?limit=20&offset=1&relationships=true&search=has_test_results%3Dtrue+or+has_policy%3Dtrue",
    "last": "/api/compliance/systems?limit=20&offset=3&relationships=true&search=has_test_results%3Dtrue+or+has_policy%3Dtrue",
    "next": "/api/compliance/systems?limit=20&offset=2&relationships=true&search=has_test_results%3Dtrue+or+has_policy%3Dtrue"
  }
}
```

### `GET /systems/{id:uuid}` - show system detail
```json
{
  "data": {
    "id": "54322ed4-3ccc-4ad7-8acb-749d1878e112",
    "type": "host",
    "attributes": {
      "name": "ortiz.name",
      "os_major_version": 8,
      "os_minor_version": 6,
      "last_scanned": "Never",
      "rules_passed": 0,
      "rules_failed": 0,
      "has_policy": true,
      "culled_timestamp": "2032-11-04T14:14:30Z",
      "stale_timestamp": "2032-10-21T14:14:30Z",
      "stale_warning_timestamp": "2032-10-28T14:14:30Z",
      "updated": "2022-10-21T14:14:30Z",
      "insights_id": "9a3acaf0-3378-013b-ca1f-1ab2effbf581",
      "compliant": true
    },

  },
}
```

### `GET /system/{id:uuid}/policies` - list policies for given system
```json
{
  "data": [
    {
      "id": "2a40fd66-6385-434b-b55e-1f484030f9d2",
      "type": "policy",
      "attributes": {
        "ref_id": "xccdf_org.ssgproject.content_profile_CS2",
        "score": 50.0,
        "parent_profile_id": "3f1eb913-6aed-47ce-a81d-60158b166340",
        "external": false,
        "compliance_threshold": 97.0,
        "os_major_version": "6",
        "os_version": "6.8",
        "policy_profile_id": "2a40fd66-6385-434b-b55e-1f484030f9d2",
        "os_minor_version": "8",
        "parent_profile_ref_id": "xccdf_org.ssgproject.content_profile_CS2",
        "name": "Example Server Profile",
        "description": "This prfile is an example of a customized server profile.",
        "canonical": false,
        "tailored": true,
        "total_host_count": 12,
        "ssg_version": "0.1.28",
        "compliant_host_count": 2,
        "test_result_host_count": 6,
        "unsupported_host_count": 0,
        "business_objective": "example",
        "policy_type": "Example Server Profile"
      }
    }
  ]
}
```

### `GET /systems/{id:uuid}/policies/{id:uuid}` - get policy scoped to system
```json
{
  "data": {
    "id": "2a40fd66-6385-434b-b55e-1f484030f9d2",
    "type": "policy",
    "attributes": {
      "ref_id": "xccdf_org.ssgproject.content_profile_CS2",
      "score": 50.0,
      "parent_profile_id": "3f1eb913-6aed-47ce-a81d-60158b166340",
      "external": false,
      "compliance_threshold": 97.0,
      "os_major_version": "6",
      "os_version": "6.8",
      "policy_profile_id": "2a40fd66-6385-434b-b55e-1f484030f9d2",
      "os_minor_version": "8",
      "parent_profile_ref_id": "xccdf_org.ssgproject.content_profile_CS2",
      "name": "Example Server Profile",
      "description": "This prfile is an example of a customized server profile.",
      "canonical": false,
      "tailored": true,
      "total_host_count": 12,
      "ssg_version": "0.1.28",
      "compliant_host_count": 2,
      "test_result_host_count": 6,
      "unsupported_host_count": 0,
      "business_objective": "example",
      "policy_type": "Example Server Profile"
    }
  }
}
```

### `GET /systems/{id:uuid}/profiles` - list profiles system is assigned to
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
  ]
}
```

### `GET /systems/{id:uuid}/profiles/{id:uuid}` - get specific profile scoped to system
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

### `GET /systems/{id:uuid}/profiles/{id:uuid}/rules` - get rules for selected profile
```json
{
  "data": [
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
    },
    {
      //...rule2
    }
  ]
}
```
