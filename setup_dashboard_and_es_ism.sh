curl -X PUT "$ES_ENDPOINT/_opendistro/_ism/policies/log-policy" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "description": "Demonstrate a hot-warm-cold-delete workflow.",
    "default_state": "hot",
    "schema_version": 1,
    "states": [{
        "name": "hot",
        "actions": [
          {
            "rollover": {
              "min_index_age": "1d",
              "min_size": "20gb"
            }
          }
        ],
        "transitions": [{
          "state_name": "warm"
        }]
      },
      {
        "name": "warm",
        "actions": [{
          "replica_count": {
            "number_of_replicas": 0
          }
        },
        {
           "index_priority": {
           "priority": 50
           }
        },
        {
          "force_merge": {
            "max_num_segments": 1
          }
        }],
        "transitions": [{
          "state_name": "cold",
          "conditions": {
            "min_index_age": "2d"
          }
        }]
      },
      {
        "name": "cold",
        "actions": [
        {
          "read_only": {}
        }],
        "transitions": [{
          "state_name": "delete",
          "conditions": {
             "min_index_age": "7d"
          }
        }]
      },
      {
        "name": "delete",
        "actions": [
        {
          "delete": {}
        }]
      }
    ],
    "ism_template": {
      "index_patterns": ["logs*"],
      "priority": 100
    }
  }
}
'

curl -X PUT "$ES_ENDPOINT/_index_template/logs_rollover_mapping" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["logs*"],
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1,
      "opendistro.index_state_management.policy_id": "log-policy",
      "opendistro.index_state_management.rollover_alias": "logs"
    },
    "mappings": {
      "properties": {
        "timestamp": {
          "type": "date"
        }
      }
    }
  }
}'

LOGS_INDEX_EXIST=$(curl -I "$ES_ENDPOINT/logs" --insecure -u "$ES_USER:$ES_PASSWORD")

# $LOGS_INDEX_EXIST will look like this : HTTP/1.1 200 OK content-type: application/json; charset=UTF-8 content-length: 332
# so then ${LOGS_INDEX_EXIST:9:3} == 200

if [ ${LOGS_INDEX_EXIST:9:3} = "200" ]; then # if index "logs" exists
  curl -X PUT "$ES_ENDPOINT/logs-000001" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json'

  curl -X POST "$ES_ENDPOINT/_reindex" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d' 
  {
    "source": {
      "index": "logs"
    },
    "dest": {
      "index": "logs-000001"
    }
  }'

  curl -X POST "$ES_ENDPOINT/_aliases" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d'
  {
    "actions" : [
      {
        "add": {
          "index": "logs-000001",
          "alias": "logs",
          "is_write_index": true
        }
      },
      { "remove_index": { "index": "logs" } }  
    ]
  }'
else
  curl -X PUT "$ES_ENDPOINT/logs-000001" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d'
  {
    "aliases": {
      "logs": {
        "is_write_index": true
      }
    }
  }'
fi

curl -X GET "$ES_ENDPOINT/_opendistro/_ism/explain/logs-000001" --insecure -u "$ES_USER:$ES_PASSWORD"

curl -XPOST "$KB_ENDPOINT/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" -H "securitytenant: global" \
  --form file=@dashboard.ndjson \
  -u "$ES_USER:$ES_PASSWORD"

###############################
# opni-drain-model-status index

curl -X PUT "$ES_ENDPOINT/_opendistro/_ism/policies/opni-drain-model-status-policy" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d'
{
    "policy": {
        "policy_id": "opni-drain-model-status-policy",
        "description": "A hot-warm-cold-delete workflow for the opni-drain-model-status index.",
        "schema_version": 1,
        "error_notification": null,
        "default_state": "hot",
        "states": [
            {
                "name": "hot",
                "actions": [
                    {
                        "rollover": {
                            "min_size": "1gb",
                            "min_index_age": "1d"
                        }
                    }
                ],
                "transitions": [
                    {
                        "state_name": "warm"
                    }
                ]
            },
            {
                "name": "warm",
                "actions": [
                    {
                        "replica_count": {
                            "number_of_replicas": 0
                        }
                    },
                    {
                        "index_priority": {
                            "priority": 50
                        }
                    },
                    {
                        "force_merge": {
                            "max_num_segments": 1
                        }
                    }
                ],
                "transitions": [
                    {
                        "state_name": "cold",
                        "conditions": {
                            "min_index_age": "5d"
                        }
                    }
                ]
            },
            {
                "name": "cold",
                "actions": [
                    {
                        "read_only": {}
                    }
                ],
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_index_age": "30d"
                        }
                    }
                ]
            },
            {
                "name": "delete",
                "actions": [
                    {
                        "delete": {}
                    }
                ],
                "transitions": []
            }
        ],
        "ism_template": {
            "index_patterns": [
                "opni-drain-model-status*"
            ],
            "priority": 100
        }
    }
}
'


curl -X PUT "$ES_ENDPOINT/_index_template/opni-drain-model-status_rollover_mapping" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["opni-drain-model-status*"],
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1,
      "opendistro.index_state_management.policy_id": "opni-drain-model-status-policy",
      "opendistro.index_state_management.rollover_alias": "opni-drain-model-status"
    },
    "mappings": {
      "properties": {
        "num_log_clusters":    { "type": "integer" },
        "update_type":  { "type": "keyword"  },
        "timestamp":   {
          "type": "date",
          "format": "epoch_millis"
        }
      }
    }
  }
}
'

curl -X PUT "$ES_ENDPOINT/opni-drain-model-status-000001" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "opni-drain-model-status": {
      "is_write_index": true
    }
  }
}
'

