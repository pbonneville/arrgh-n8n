"""
n8n LangChain Node Simulator

This module provides local simulation of n8n's LangChain nodes to enable
accurate testing and development before deployment.
"""

import json
import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional, Union
from dataclasses import dataclass
from abc import ABC, abstractmethod

try:
    from langchain.agents import AgentExecutor
    from langchain.memory import ConversationBufferWindowMemory
    from langchain.schema import BaseMessage, HumanMessage, AIMessage
    LANGCHAIN_AVAILABLE = True
except ImportError:
    LANGCHAIN_AVAILABLE = False
    AgentExecutor = None
    ConversationBufferWindowMemory = None


@dataclass
class N8nNodeInput:
    """Represents input data to an n8n node"""
    json: Dict[str, Any]
    binary: Optional[Dict[str, Any]] = None
    
    def to_dict(self) -> Dict[str, Any]:
        result = {"json": self.json}
        if self.binary:
            result["binary"] = self.binary
        return result


@dataclass
class N8nNodeOutput:
    """Represents output data from an n8n node"""
    json: Dict[str, Any]
    binary: Optional[Dict[str, Any]] = None
    
    def to_dict(self) -> Dict[str, Any]:
        result = {"json": self.json}
        if self.binary:
            result["binary"] = self.binary
        return result


class N8nNodeSimulator(ABC):
    """Base class for n8n node simulators"""
    
    def __init__(self, node_id: str, node_name: str, node_type: str):
        self.node_id = node_id
        self.node_name = node_name
        self.node_type = node_type
        self.execution_count = 0
    
    @abstractmethod
    def execute(self, input_data: N8nNodeInput) -> N8nNodeOutput:
        """Execute the node with given input data"""
        pass
    
    def _log_execution(self, input_data: N8nNodeInput, output_data: N8nNodeOutput):
        """Log node execution for debugging"""
        self.execution_count += 1
        print(f"[{self.node_name}] Execution #{self.execution_count}")
        print(f"Input keys: {list(input_data.json.keys())}")
        print(f"Output keys: {list(output_data.json.keys())}")


class N8nAiAgentSimulator(N8nNodeSimulator):
    """Simulates n8n's AI Agent node"""
    
    def __init__(
        self,
        node_id: str = None,
        node_name: str = "AI Agent",
        agent_executor: Optional[AgentExecutor] = None,
        system_message: str = "",
        max_iterations: int = 5,
        temperature: float = 0.1
    ):
        super().__init__(
            node_id or str(uuid.uuid4()),
            node_name,
            "@n8n/n8n-nodes-langchain.agent"
        )
        self.agent_executor = agent_executor
        self.system_message = system_message
        self.max_iterations = max_iterations
        self.temperature = temperature
        
        if not LANGCHAIN_AVAILABLE:
            print("Warning: LangChain not available, using mock responses")
    
    def execute(self, input_data: N8nNodeInput) -> N8nNodeOutput:
        """Execute AI Agent simulation"""
        start_time = datetime.now()
        
        try:
            if self.agent_executor and LANGCHAIN_AVAILABLE:
                # Use real LangChain agent
                result = self._execute_real_agent(input_data)
            else:
                # Use mock agent for testing
                result = self._execute_mock_agent(input_data)
            
            processing_time = (datetime.now() - start_time).total_seconds() * 1000
            
            # Add execution metadata
            if isinstance(result, dict):
                result["processing_metadata"] = {
                    "processed_at": datetime.now().isoformat(),
                    "processing_time_ms": round(processing_time, 2),
                    "node_id": self.node_id,
                    "node_name": self.node_name,
                    "execution_count": self.execution_count + 1
                }
            
            output = N8nNodeOutput(json=result)
            self._log_execution(input_data, output)
            
            return output
            
        except Exception as e:
            error_output = N8nNodeOutput(json={
                "error": str(e),
                "error_type": type(e).__name__,
                "processing_status": "failed",
                "timestamp": datetime.now().isoformat()
            })
            self._log_execution(input_data, error_output)
            return error_output
    
    def _execute_real_agent(self, input_data: N8nNodeInput) -> Dict[str, Any]:
        """Execute with real LangChain agent"""
        email_data = input_data.json.get("email_data", input_data.json)
        
        # Format input for agent
        agent_input = {
            "email_from": email_data.get("from", ""),
            "email_subject": email_data.get("subject", ""),
            "email_body": email_data.get("body", "")
        }
        
        # Execute agent
        result = self.agent_executor.invoke(agent_input)
        
        # Try to parse JSON response
        output_text = result.get("output", "")
        try:
            parsed_result = json.loads(output_text)
            return parsed_result
        except json.JSONDecodeError:
            # If not JSON, wrap in standard format
            return {
                "category": "general",
                "priority": "medium",
                "confidence": 0.8,
                "entities": {},
                "suggested_actions": ["Review email manually"],
                "reasoning": output_text,
                "raw_response": output_text
            }
    
    def _execute_mock_agent(self, input_data: N8nNodeInput) -> Dict[str, Any]:
        """Execute with mock agent for testing"""
        email_data = input_data.json.get("email_data", input_data.json)
        
        subject = email_data.get("subject", "").lower()
        body = email_data.get("body", "").lower()
        
        # Simple categorization logic
        if any(keyword in subject + " " + body for keyword in ["invoice", "bill", "payment"]):
            category = "invoice"
            priority = "medium"
            actions = ["Forward to accounting", "Process payment"]
        elif any(keyword in subject + " " + body for keyword in ["urgent", "help", "support"]):
            category = "support"
            priority = "high"
            actions = ["Escalate to support team", "Respond within 2 hours"]
        elif any(keyword in subject + " " + body for keyword in ["proposal", "meeting", "demo"]):
            category = "sales"
            priority = "medium"
            actions = ["Forward to sales team", "Schedule follow-up"]
        else:
            category = "general"
            priority = "low"
            actions = ["File in general inbox", "Review when convenient"]
        
        return {
            "category": category,
            "priority": priority,
            "confidence": 0.85,
            "entities": {
                "sender": email_data.get("from", ""),
                "keywords": self._extract_keywords(subject + " " + body)
            },
            "suggested_actions": actions,
            "reasoning": f"Classified as {category} based on content analysis. Priority set to {priority} based on keywords and context.",
            "mock_response": True
        }
    
    def _extract_keywords(self, text: str) -> List[str]:
        """Extract keywords from text"""
        keywords = []
        important_words = [
            "invoice", "bill", "payment", "due", "urgent", "asap",
            "support", "help", "issue", "problem", "proposal", 
            "meeting", "demo", "opportunity"
        ]
        
        for word in important_words:
            if word in text.lower():
                keywords.append(word)
        
        return keywords[:5]  # Limit to top 5


class N8nMemorySimulator(N8nNodeSimulator):
    """Simulates n8n's Memory Buffer Window node"""
    
    def __init__(
        self,
        node_id: str = None,
        node_name: str = "Memory Buffer",
        window_size: int = 5,
        return_messages: bool = True
    ):
        super().__init__(
            node_id or str(uuid.uuid4()),
            node_name,
            "@n8n/n8n-nodes-langchain.memoryBufferWindow"
        )
        self.window_size = window_size
        self.return_messages = return_messages
        self.message_buffer = []
        self.conversation_threads = {}
    
    def execute(self, input_data: N8nNodeInput) -> N8nNodeOutput:
        """Execute memory buffer simulation"""
        email_data = input_data.json.get("email_data", input_data.json)
        
        # Extract thread identifier
        thread_id = email_data.get("thread_id", "default")
        
        # Add to conversation thread
        if thread_id not in self.conversation_threads:
            self.conversation_threads[thread_id] = []
        
        # Create memory entry
        memory_entry = {
            "timestamp": datetime.now().isoformat(),
            "thread_id": thread_id,
            "message_id": email_data.get("id", str(uuid.uuid4())),
            "from": email_data.get("from", ""),
            "subject": email_data.get("subject", ""),
            "content_preview": email_data.get("body", "")[:100] + "..." if len(email_data.get("body", "")) > 100 else email_data.get("body", "")
        }
        
        # Add to thread and global buffer
        self.conversation_threads[thread_id].append(memory_entry)
        self.message_buffer.append(memory_entry)
        
        # Maintain window size
        if len(self.message_buffer) > self.window_size:
            self.message_buffer.pop(0)
        
        # Maintain thread window size
        if len(self.conversation_threads[thread_id]) > self.window_size:
            self.conversation_threads[thread_id].pop(0)
        
        output = N8nNodeOutput(json={
            "memory_context": {
                "current_thread": thread_id,
                "thread_messages": self.conversation_threads[thread_id] if self.return_messages else [],
                "recent_messages": self.message_buffer if self.return_messages else [],
                "thread_count": len(self.conversation_threads),
                "total_messages": sum(len(thread) for thread in self.conversation_threads.values())
            },
            "memory_summary": {
                "active_threads": list(self.conversation_threads.keys()),
                "window_size": self.window_size,
                "buffer_utilization": len(self.message_buffer) / self.window_size
            }
        })
        
        self._log_execution(input_data, output)
        return output


class N8nPythonCodeSimulator(N8nNodeSimulator):
    """Simulates n8n's Python Code node"""
    
    def __init__(
        self,
        node_id: str = None,
        node_name: str = "Python Code",
        python_code: str = ""
    ):
        super().__init__(
            node_id or str(uuid.uuid4()),
            node_name,
            "n8n-nodes-base.code"
        )
        self.python_code = python_code
    
    def execute(self, input_data: N8nNodeInput) -> N8nNodeOutput:
        """Execute Python code simulation"""
        # Create a simplified execution environment
        execution_context = {
            "$input": MockN8nInput(input_data),
            "$json": input_data.json,
            "json": json,
            "datetime": datetime,
            "uuid": uuid
        }
        
        try:
            # Execute the Python code
            exec(self.python_code, execution_context)
            
            # Get the return value (last expression or explicit return)
            if "return" in execution_context:
                result = execution_context["return"]
            else:
                # Look for common output variables
                result = execution_context.get("result", execution_context.get("output", input_data.json))
            
            output = N8nNodeOutput(json=result if isinstance(result, dict) else {"result": result})
            self._log_execution(input_data, output)
            return output
            
        except Exception as e:
            error_output = N8nNodeOutput(json={
                "error": str(e),
                "error_type": type(e).__name__,
                "code_execution_failed": True,
                "timestamp": datetime.now().isoformat()
            })
            self._log_execution(input_data, error_output)
            return error_output


class MockN8nInput:
    """Mock n8n $input object for Python code simulation"""
    
    def __init__(self, input_data: N8nNodeInput):
        self.input_data = input_data
    
    def first(self):
        """Return the first (and usually only) input item"""
        return MockN8nInputItem(self.input_data)
    
    def all(self):
        """Return all input items (simplified to just one)"""
        return [self.first()]


class MockN8nInputItem:
    """Mock n8n input item"""
    
    def __init__(self, input_data: N8nNodeInput):
        self.json = input_data.json
        self.binary = input_data.binary or {}


class N8nWorkflowSimulator:
    """Simulates a complete n8n workflow"""
    
    def __init__(self, workflow_name: str = "Simulated Workflow"):
        self.workflow_name = workflow_name
        self.nodes = {}
        self.connections = {}
        self.execution_history = []
    
    def add_node(self, node: N8nNodeSimulator):
        """Add a node to the workflow"""
        self.nodes[node.node_name] = node
    
    def add_connection(self, source_node: str, target_node: str, connection_type: str = "main"):
        """Add a connection between nodes"""
        if source_node not in self.connections:
            self.connections[source_node] = {}
        if connection_type not in self.connections[source_node]:
            self.connections[source_node][connection_type] = []
        
        self.connections[source_node][connection_type].append(target_node)
    
    def execute_workflow(self, initial_input: Dict[str, Any], start_node: str) -> Dict[str, Any]:
        """Execute the workflow starting from a specific node"""
        execution_id = str(uuid.uuid4())
        execution_start = datetime.now()
        
        print(f"Starting workflow execution: {execution_id}")
        print(f"Workflow: {self.workflow_name}")
        print(f"Start node: {start_node}")
        
        # Track execution path
        execution_path = []
        current_data = N8nNodeInput(json=initial_input)
        
        # Execute nodes in sequence
        current_node = start_node
        while current_node and current_node in self.nodes:
            print(f"\nExecuting node: {current_node}")
            
            # Execute current node
            node = self.nodes[current_node]
            output = node.execute(current_data)
            
            execution_path.append({
                "node_name": current_node,
                "node_type": node.node_type,
                "input": current_data.to_dict(),
                "output": output.to_dict(),
                "timestamp": datetime.now().isoformat()
            })
            
            # Prepare data for next node
            current_data = N8nNodeInput(json=output.json)
            
            # Find next node
            if current_node in self.connections and "main" in self.connections[current_node]:
                next_nodes = self.connections[current_node]["main"]
                current_node = next_nodes[0] if next_nodes else None
            else:
                current_node = None
        
        execution_end = datetime.now()
        execution_time = (execution_end - execution_start).total_seconds()
        
        # Create execution summary
        execution_summary = {
            "execution_id": execution_id,
            "workflow_name": self.workflow_name,
            "start_time": execution_start.isoformat(),
            "end_time": execution_end.isoformat(),
            "execution_time_seconds": round(execution_time, 3),
            "nodes_executed": len(execution_path),
            "final_output": current_data.to_dict(),
            "execution_path": execution_path,
            "status": "completed"
        }
        
        self.execution_history.append(execution_summary)
        
        print(f"\nWorkflow execution completed in {execution_time:.3f} seconds")
        print(f"Nodes executed: {len(execution_path)}")
        
        return execution_summary


# Example usage and testing
if __name__ == "__main__":
    # Create a simple workflow simulation
    workflow = N8nWorkflowSimulator("Email Processing Test")
    
    # Add nodes
    preprocessor = N8nPythonCodeSimulator(
        node_name="Prepare Email Data",
        python_code="""
# Simple preprocessing
result = {
    "email_data": {
        "id": $json.get("messageId", "test-123"),
        "from": $json.get("from", ""),
        "subject": $json.get("subject", ""),
        "body": $json.get("body", ""),
        "thread_id": "test-thread"
    }
}
"""
    )
    
    ai_agent = N8nAiAgentSimulator(
        node_name="AI Email Processor",
        system_message="Analyze emails and categorize them."
    )
    
    memory = N8nMemorySimulator(
        node_name="Email Memory",
        window_size=3
    )
    
    # Add nodes to workflow
    workflow.add_node(preprocessor)
    workflow.add_node(ai_agent)
    workflow.add_node(memory)
    
    # Add connections
    workflow.add_connection("Prepare Email Data", "AI Email Processor")
    workflow.add_connection("AI Email Processor", "Email Memory")
    
    # Test with sample email
    test_email = {
        "messageId": "test-001",
        "from": "billing@example.com",
        "subject": "Invoice #12345 - Payment Due",
        "body": "Please find attached invoice #12345 for $2,500.00. Payment is due within 30 days."
    }
    
    # Execute workflow
    result = workflow.execute_workflow(test_email, "Prepare Email Data")
    
    print("\n=== Execution Summary ===")
    print(f"Status: {result['status']}")
    print(f"Execution time: {result['execution_time_seconds']} seconds")
    print(f"Nodes executed: {result['nodes_executed']}")