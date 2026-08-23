# API Index Schema

The project-local JSON index uses this minimum contract:

```json
{
  "schema_version": 1,
  "generated_at_utc": "ISO-8601",
  "metadata": {
    "route_count": 1,
    "sources": [
      { "path": "backend/routes.go", "sha256": "lowercase-hex" }
    ],
    "warnings": []
  },
  "routes": [
    {
      "method": "GET",
      "path": "/meetings/{id}",
      "summary": "Get meeting detail",
      "description": "",
      "tags": ["meeting"],
      "operation_id": "getMeeting",
      "auth_hint": "unknown",
      "handler": "GetMeeting",
      "parameters": [],
      "request_schemas": [],
      "response_schemas": [],
      "sources": [
        { "kind": "code", "path": "backend/routes.go", "line": 42 }
      ]
    }
  ]
}
```

Additional fields are allowed. Method is uppercase and path starts with `/`. Merge duplicate method/path records and retain all evidence sources. An auth hint is only a discovery clue; verify middleware and handler code before reporting an authentication boundary.
