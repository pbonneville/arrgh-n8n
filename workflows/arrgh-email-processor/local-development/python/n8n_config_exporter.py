"""
n8n Configuration Exporter

This module provides utilities to export local LangGraph and agent configurations
to n8n-compatible node configurations.
"""

import json
import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional, Union
from dataclasses import dataclass, asdict
from pathlib import Path


@dataclass
class N8nNodePosition:
    """Represents node position in n8n workflow canvas"""
    x: int
    y: int
    
    def to_list(self) -> List[int]:
        return [self.x, self.y]


@dataclass
class N8nModelConfig:
    """Configuration for AI model in n8n"""
    provider: str = "anthropic"
    model_name: str = "claude-sonnet-4-20250514"
    display_name: str = "Claude 4 Sonnet"
    temperature: float = 0.1
    max_tokens: Optional[int] = None
    
    def to_n8n_format(self) -> Dict[str, Any]:
        """Convert to n8n model configuration format"""
        return {
            "__rl": True,
            "mode": "list",
            "value": self.model_name,
            "cachedResultName": self.display_name
        }


@dataclass
class N8nCredentialRef:
    """Reference to n8n credentials"""
    credential_id: str
    credential_name: str
    credential_type: str
    
    def to_n8n_format(self) -> Dict[str, Any]:
        """Convert to n8n credential reference format"""
        return {
            self.credential_type: {
                "id": self.credential_id,
                "name": self.credential_name
            }
        }


class N8nConfigExporter:
    """Main class for exporting configurations to n8n format"""
    
    def __init__(self, workflow_name: str = "Generated Workflow"):
        self.workflow_name = workflow_name
        self.nodes = []
        self.connections = {}
        self.generated_at = datetime.now()
        
        # Default credentials (update these with actual values)
        self.default_credentials = {
            "anthropic": N8nCredentialRef(
                credential_id="JfNCHfdN0o9xewV4",
                credential_name="Anthropic account",
                credential_type="anthropicApi"
            ),
            "openai": N8nCredentialRef(
                credential_id="azBh8GIYeAQwMZCI",
                credential_name="OpenAi account",
                credential_type="openAiApi"
            ),
            "aws": N8nCredentialRef(
                credential_id="pex7iOrrjZtJ7qua",
                credential_name="AWS account",
                credential_type="aws"
            )
        }
    
    def create_ai_agent_node(
        self,
        name: str,
        system_message: str,
        position: N8nNodePosition,
        model_config: Optional[N8nModelConfig] = None,
        agent_type: str = "conversationalAgent",
        max_iterations: int = 5,
        temperature: float = 0.1,
        tools: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """Create an AI Agent node configuration"""
        
        if model_config is None:
            model_config = N8nModelConfig()
        
        node_config = {
            "parameters": {
                "agent": agent_type,
                "model": model_config.to_n8n_format(),
                "systemMessage": system_message,
                "options": {
                    "maxIterations": max_iterations,
                    "returnIntermediateSteps": True,
                    "temperature": temperature
                }
            },
            "type": "@n8n/n8n-nodes-langchain.agent",
            "typeVersion": 1.8,
            "position": position.to_list(),
            "id": str(uuid.uuid4()),
            "name": name
        }
        
        # Add credentials based on model provider
        if model_config.provider in self.default_credentials:
            credential = self.default_credentials[model_config.provider]
            node_config["credentials"] = credential.to_n8n_format()
        
        # Add tools if specified
        if tools:
            node_config["parameters"]["tools"] = tools
        
        return node_config
    
    def create_memory_node(
        self,
        name: str,
        position: N8nNodePosition,
        memory_type: str = "bufferWindow",
        window_size: int = 5,
        return_messages: bool = True,
        input_key: str = "input",
        output_key: str = "history"
    ) -> Dict[str, Any]:
        """Create a Memory node configuration"""
        
        type_mapping = {
            "bufferWindow": "@n8n/n8n-nodes-langchain.memoryBufferWindow",
            "redis": "@n8n/n8n-nodes-langchain.memoryChatRedis",
            "mongodb": "@n8n/n8n-nodes-langchain.memoryChatMongodb"
        }
        
        node_config = {
            "parameters": {
                "returnMessages": return_messages,
                "inputKey": input_key,
                "outputKey": output_key
            },
            "type": type_mapping.get(memory_type, type_mapping["bufferWindow"]),
            "typeVersion": 1.3,
            "position": position.to_list(),
            "id": str(uuid.uuid4()),
            "name": name
        }
        
        # Add memory-specific parameters
        if memory_type == "bufferWindow":
            node_config["parameters"]["windowSize"] = window_size
        
        return node_config
    
    def create_python_code_node(
        self,
        name: str,
        python_code: str,
        position: N8nNodePosition,
        language: str = "python"
    ) -> Dict[str, Any]:
        """Create a Python Code node configuration"""
        
        return {
            "parameters": {
                "language": language,
                "pythonCode": python_code
            },
            "type": "n8n-nodes-base.code",
            "typeVersion": 2,
            "position": position.to_list(),
            "id": str(uuid.uuid4()),
            "name": name
        }
    
    def create_http_request_node(
        self,
        name: str,
        url: str,
        method: str,
        position: N8nNodePosition,
        authentication: Optional[str] = None,
        credential_type: Optional[str] = None,
        headers: Optional[Dict[str, str]] = None,
        body: Optional[str] = None
    ) -> Dict[str, Any]:
        """Create an HTTP Request node configuration"""
        
        node_config = {
            "parameters": {
                "url": url,
                "options": {}
            },
            "type": "n8n-nodes-base.httpRequest",
            "typeVersion": 4.1,
            "position": position.to_list(),
            "id": str(uuid.uuid4()),
            "name": name
        }
        
        # Set HTTP method if not GET
        if method.upper() != "GET":
            node_config["parameters"]["httpMethod"] = method.upper()
        
        # Add authentication
        if authentication and credential_type:
            node_config["parameters"]["authentication"] = authentication
            node_config["parameters"]["nodeCredentialType"] = credential_type
            
            if credential_type in self.default_credentials:
                credential = self.default_credentials[credential_type]
                node_config["credentials"] = credential.to_n8n_format()
        
        # Add headers
        if headers:
            node_config["parameters"]["options"]["headers"] = headers
        
        # Add body
        if body:
            node_config["parameters"]["options"]["body"] = body
        
        return node_config
    
    def create_webhook_node(
        self,
        name: str,
        path: str,
        position: N8nNodePosition,
        http_method: str = "POST",
        response_mode: str = "responseNode",
        webhook_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Create a Webhook node configuration"""
        
        node_config = {
            "parameters": {
                "httpMethod": http_method,
                "path": path,
                "responseMode": response_mode,
                "options": {}
            },
            "type": "n8n-nodes-base.webhook",
            "typeVersion": 1,
            "position": position.to_list(),
            "id": str(uuid.uuid4()),
            "name": name
        }
        
        if webhook_id:
            node_config["webhookId"] = webhook_id
        
        return node_config
    
    def create_if_node(
        self,
        name: str,
        position: N8nNodePosition,
        conditions: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Create an IF condition node configuration"""
        
        return {
            "parameters": {
                "conditions": {
                    "string": conditions
                }
            },
            "type": "n8n-nodes-base.if",
            "typeVersion": 1,
            "position": position.to_list(),
            "id": str(uuid.uuid4()),
            "name": name
        }
    
    def create_respond_to_webhook_node(
        self,
        name: str,
        position: N8nNodePosition,
        response_body: str = "Success",
        respond_with: str = "text",
        status_code: int = 200
    ) -> Dict[str, Any]:
        """Create a Respond to Webhook node configuration"""
        
        return {
            "parameters": {
                "respondWith": respond_with,
                "responseBody": response_body,
                "options": {
                    "responseCode": status_code
                }
            },
            "type": "n8n-nodes-base.respondToWebhook",
            "typeVersion": 1,
            "position": position.to_list(),
            "id": str(uuid.uuid4()),
            "name": name
        }
    
    def add_node(self, node_config: Dict[str, Any]) -> str:\n        \"\"\"Add a node to the workflow and return its ID\"\"\"\n        self.nodes.append(node_config)\n        return node_config[\"id\"]\n    \n    def add_connection(\n        self,\n        source_node_name: str,\n        target_node_name: str,\n        connection_type: str = \"main\",\n        source_output_index: int = 0,\n        target_input_index: int = 0\n    ):\n        \"\"\"Add a connection between two nodes\"\"\"\n        \n        if source_node_name not in self.connections:\n            self.connections[source_node_name] = {}\n        \n        if connection_type not in self.connections[source_node_name]:\n            self.connections[source_node_name][connection_type] = []\n        \n        # Ensure we have enough output arrays\n        while len(self.connections[source_node_name][connection_type]) <= source_output_index:\n            self.connections[source_node_name][connection_type].append([])\n        \n        # Add the connection\n        self.connections[source_node_name][connection_type][source_output_index].append({\n            \"node\": target_node_name,\n            \"type\": connection_type,\n            \"index\": target_input_index\n        })\n    \n    def export_workflow(\n        self,\n        active: bool = False,\n        tags: Optional[List[str]] = None\n    ) -> Dict[str, Any]:\n        \"\"\"Export the complete workflow configuration\"\"\"\n        \n        workflow = {\n            \"name\": self.workflow_name,\n            \"nodes\": self.nodes,\n            \"connections\": self.connections,\n            \"active\": active,\n            \"settings\": {\n                \"executionOrder\": \"v1\"\n            },\n            \"staticData\": None,\n            \"meta\": {\n                \"templateCredsSetupCompleted\": True,\n                \"generated_by\": \"n8n-config-exporter\",\n                \"generated_at\": self.generated_at.isoformat(),\n                \"version\": \"1.0.0\"\n            },\n            \"pinData\": {},\n            \"tags\": tags or []\n        }\n        \n        return workflow\n    \n    def save_workflow(\n        self,\n        file_path: Union[str, Path],\n        active: bool = False,\n        tags: Optional[List[str]] = None\n    ):\n        \"\"\"Save the workflow to a JSON file\"\"\"\n        \n        workflow = self.export_workflow(active=active, tags=tags)\n        \n        with open(file_path, 'w') as f:\n            json.dump(workflow, f, indent=2)\n        \n        print(f\"Workflow saved to: {file_path}\")\n        print(f\"Nodes: {len(self.nodes)}\")\n        print(f\"Connections: {len(self.connections)}\")\n    \n    def export_individual_nodes(\n        self,\n        output_dir: Union[str, Path]\n    ) -> List[str]:\n        \"\"\"Export individual node configurations to separate files\"\"\"\n        \n        output_dir = Path(output_dir)\n        output_dir.mkdir(exist_ok=True)\n        \n        exported_files = []\n        \n        for node in self.nodes:\n            # Create filename from node name\n            filename = f\"{node['name'].lower().replace(' ', '-')}-config.json\"\n            file_path = output_dir / filename\n            \n            with open(file_path, 'w') as f:\n                json.dump(node, f, indent=2)\n            \n            exported_files.append(str(file_path))\n            print(f\"Exported node: {node['name']} -> {filename}\")\n        \n        return exported_files\n    \n    def validate_workflow(self) -> Dict[str, Any]:\n        \"\"\"Validate the workflow configuration\"\"\"\n        \n        validation_results = {\n            \"valid\": True,\n            \"errors\": [],\n            \"warnings\": [],\n            \"stats\": {\n                \"total_nodes\": len(self.nodes),\n                \"total_connections\": sum(len(connections) for connections in self.connections.values()),\n                \"node_types\": {}\n            }\n        }\n        \n        # Collect node type statistics\n        for node in self.nodes:\n            node_type = node.get(\"type\", \"unknown\")\n            validation_results[\"stats\"][\"node_types\"][node_type] = validation_results[\"stats\"][\"node_types\"].get(node_type, 0) + 1\n        \n        # Validate node structure\n        required_node_fields = [\"id\", \"name\", \"type\", \"parameters\", \"position\"]\n        for i, node in enumerate(self.nodes):\n            missing_fields = [field for field in required_node_fields if field not in node]\n            if missing_fields:\n                validation_results[\"errors\"].append(f\"Node {i}: Missing fields {missing_fields}\")\n                validation_results[\"valid\"] = False\n        \n        # Validate connections reference existing nodes\n        node_names = {node[\"name\"] for node in self.nodes}\n        for source_node, connections in self.connections.items():\n            if source_node not in node_names:\n                validation_results[\"errors\"].append(f\"Connection source '{source_node}' not found in nodes\")\n                validation_results[\"valid\"] = False\n            \n            for connection_type, connection_arrays in connections.items():\n                for connection_array in connection_arrays:\n                    for connection in connection_array:\n                        target_node = connection.get(\"node\")\n                        if target_node not in node_names:\n                            validation_results[\"errors\"].append(f\"Connection target '{target_node}' not found in nodes\")\n                            validation_results[\"valid\"] = False\n        \n        # Check for isolated nodes (no connections)\n        connected_nodes = set()\n        connected_nodes.update(self.connections.keys())\n        for connections in self.connections.values():\n            for connection_type, connection_arrays in connections.items():\n                for connection_array in connection_arrays:\n                    for connection in connection_array:\n                        connected_nodes.add(connection.get(\"node\"))\n        \n        isolated_nodes = node_names - connected_nodes\n        if isolated_nodes:\n            validation_results[\"warnings\"].append(f\"Isolated nodes (no connections): {list(isolated_nodes)}\")\n        \n        return validation_results\n\n\n# Convenience functions for common configurations\ndef create_email_processing_workflow(\n    system_message: str,\n    preprocessing_code: str,\n    postprocessing_code: str,\n    webhook_path: str = \"inbound-email\"\n) -> N8nConfigExporter:\n    \"\"\"Create a complete email processing workflow\"\"\"\n    \n    exporter = N8nConfigExporter(\"Email Processing Workflow\")\n    \n    # Define positions\n    positions = {\n        \"webhook\": N8nNodePosition(920, 160),\n        \"condition_check\": N8nNodePosition(1140, 160),\n        \"subscription_confirm\": N8nNodePosition(1360, 60),\n        \"email_check\": N8nNodePosition(1360, 260),\n        \"parse_metadata\": N8nNodePosition(1580, 260),\n        \"download_email\": N8nNodePosition(1800, 260),\n        \"parse_content\": N8nNodePosition(2020, 260),\n        \"preprocess\": N8nNodePosition(2240, 260),\n        \"ai_agent\": N8nNodePosition(2460, 260),\n        \"memory\": N8nNodePosition(2460, 400),\n        \"postprocess\": N8nNodePosition(2680, 260),\n        \"respond\": N8nNodePosition(2900, 260)\n    }\n    \n    # Create nodes\n    webhook = exporter.create_webhook_node(\n        \"Webhook\",\n        webhook_path,\n        positions[\"webhook\"],\n        webhook_id=webhook_path\n    )\n    \n    preprocess = exporter.create_python_code_node(\n        \"Prepare Email Data\",\n        preprocessing_code,\n        positions[\"preprocess\"]\n    )\n    \n    ai_agent = exporter.create_ai_agent_node(\n        \"AI Email Processor\",\n        system_message,\n        positions[\"ai_agent\"]\n    )\n    \n    memory = exporter.create_memory_node(\n        \"Email Memory\",\n        positions[\"memory\"]\n    )\n    \n    postprocess = exporter.create_python_code_node(\n        \"Process Results\",\n        postprocessing_code,\n        positions[\"postprocess\"]\n    )\n    \n    respond = exporter.create_respond_to_webhook_node(\n        \"Success Response\",\n        positions[\"respond\"],\n        \"Email processed successfully\"\n    )\n    \n    # Add nodes to workflow\n    exporter.add_node(webhook)\n    exporter.add_node(preprocess)\n    exporter.add_node(ai_agent)\n    exporter.add_node(memory)\n    exporter.add_node(postprocess)\n    exporter.add_node(respond)\n    \n    # Add connections (simplified for demonstration)\n    exporter.add_connection(\"Prepare Email Data\", \"AI Email Processor\")\n    exporter.add_connection(\"Email Memory\", \"AI Email Processor\", \"ai_memory\")\n    exporter.add_connection(\"AI Email Processor\", \"Process Results\")\n    exporter.add_connection(\"Process Results\", \"Success Response\")\n    \n    return exporter\n\n\n# Example usage\nif __name__ == \"__main__\":\n    # Create a simple workflow\n    exporter = N8nConfigExporter(\"Test Workflow\")\n    \n    # Add a simple AI agent\n    ai_agent = exporter.create_ai_agent_node(\n        \"Test AI Agent\",\n        \"You are a helpful assistant.\",\n        N8nNodePosition(100, 100)\n    )\n    \n    memory = exporter.create_memory_node(\n        \"Test Memory\",\n        N8nNodePosition(100, 200)\n    )\n    \n    exporter.add_node(ai_agent)\n    exporter.add_node(memory)\n    exporter.add_connection(\"Test Memory\", \"Test AI Agent\", \"ai_memory\")\n    \n    # Validate and export\n    validation = exporter.validate_workflow()\n    print(\"Validation results:\", validation)\n    \n    if validation[\"valid\"]:\n        workflow = exporter.export_workflow()\n        print(\"\\nWorkflow exported successfully!\")\n        print(f\"Nodes: {len(workflow['nodes'])}\")\n        print(f\"Connections: {len(workflow['connections'])}\")\n    else:\n        print(\"Validation failed:\", validation[\"errors\"])