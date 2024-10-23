import json
import random

class NodeManager:
    def __init__(self, file_path='server/nodes.json'):
        self.file_path = file_path
        self.nodes = self.load_nodes()

    def load_nodes(self):
        """
        Load nodes from the JSON file and return the list of nodes.
        """
        try:
            with open(self.file_path, 'r') as file:
                data = json.load(file)
                # Check if 'nodes' key exists and is a list
                if 'nodes' in data and isinstance(data['nodes'], list):
                    return data['nodes']
                else:
                    print(f"Error: 'nodes' key missing or not a list in {self.file_path}")
                    return []
        except FileNotFoundError:
            print(f"Error: {self.file_path} not found. Please ensure the file exists.")
            return []
        except json.JSONDecodeError:
            print(f"Error: Failed to decode JSON from {self.file_path}.")
            return []

    def get_random_node(self):
        """
        Get a random node from the list of loaded nodes.
        """
        if self.nodes:
            return random.choice(self.nodes)
        else:
            print("No nodes available.")
            return None

