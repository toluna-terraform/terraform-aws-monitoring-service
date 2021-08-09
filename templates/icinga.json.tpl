[{
    "name": "icinga", 
    "mountPoints": [], 
    "image": "014931512072.dkr.ecr.us-east-1.amazonaws.com/icinga:latest", 
    "cpu": 0, 
    "portMappings": [
        {
          "hostPort": 80,
          "protocol": "tcp",
          "containerPort": 80
        }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "/ecs/td-${ENV_NAME}-icinga",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "ecs"
          }
        },
    "memoryReservation": 128, 
    "essential": true, 
    "volumesFrom": [],
    "command": [],
    "entryPoint": [],
    "environment": [
        {
          "name": "ENV_NAME",
          "value": "${SHORT_ENV_NAME}"
        },
        {
          "name": "AWS_REGION",
          "value": "us-east-1"
        },
        {
          "name": "TEAMS_URI",
          "value": "https://outlook.office.com/webhook/6a75e543-60bb-4960-96da-8dcdb7531321@6393a87a-a738-497d-ace9-37b689400feb/IncomingWebhook/7ad2ed20cb2d4d4e9bc9d1b5b4d1c634/c4bf0498-8178-4d94-ac54-fc40380d03a5"
        },
        {
          "name": "ldap_server",
          "value": "10.50.0.84"
        },
        {
          "name": "ldap_port",
          "value": "3268"
        }
      ],
      "secrets": [
        {
          "valueFrom": "ldap_auth_user",
          "name": "ldap_auth_user"
        },
        {
          "valueFrom": "ldap_auth_password",
          "name": "ldap_auth_password"
        }
      ],
    "privileged": false
}
]



