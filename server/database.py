import json
from collections import OrderedDict
import os

class BlockchainDb:
    
    @staticmethod
    def save_blockchain(blockchain, filename='server/blockchain.json'):
        """
        Save the blockchain to a JSON file in the same directory as the script.
        
        :param blockchain: The Blockchain instance to save
        :param filename: The name of the file to save the blockchain to
        """
        # Get the directory of the current script
        
        # Create the full path for the blockchain file
        file_path =filename
        
        # Use OrderedDict to maintain order and remove duplicates
        unique_chain = list(OrderedDict((json.dumps(block, sort_keys=True), block) for block in blockchain.chain).values())
        unique_transactions = list(OrderedDict((json.dumps(tx, sort_keys=True), tx) for tx in blockchain.current_transactions).values())
        
        data = {
            'chain': unique_chain,
            'current_transactions': unique_transactions,
            'nodes': list(set(blockchain.nodes)) , # Convert set to list for JSON serialization
            'ttl': blockchain.ttl
        }
        
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=4)
        print(f"Blockchain saved to {file_path}")

    @staticmethod
    def load_blockchain(blockchain, filename='server/blockchain.json'):
        """
        Load the blockchain from a JSON file in the same directory as the script.
        
        :param blockchain: The Blockchain instance to update
        :param filename: The name of the file to load the blockchain from
        :return: True if loaded successfully, False otherwise
        """
        # Get the directory of the current script
        # Create the full path for the blockchain file
        file_path = filename
        
        if not os.path.exists(file_path):
            print(f"File {file_path} not found. Starting with a new blockchain.")
            return False
        
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        # Use set to remove any potential duplicates
        chain = list(OrderedDict((json.dumps(block, sort_keys=True), block) for block in data['chain']).values())
        if blockchain.current_transactions != []:
            blockchain.current_transactions = list(OrderedDict((json.dumps(tx, sort_keys=True), tx) for tx in data['current_transactions']).values())
        blockchain.nodes = set(data['nodes'])
        blockchain.ttl = data['ttl']
        # Rebuild hash_list
        blockchain.hash_list = set(blockchain.hash(block) for block in blockchain.chain)
        
        if chain != []:
            blockchain.chain = chain
        print(f"Blockchain loaded from {file_path}")
        return True