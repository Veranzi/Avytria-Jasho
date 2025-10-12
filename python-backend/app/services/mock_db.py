"""
Mock database for development/testing when Firebase is unavailable
"""
from typing import Dict, Any, Optional, List
from datetime import datetime


class MockDatabase:
    """In-memory database for development"""
    
    def __init__(self):
        self.users: Dict[str, Dict[str, Any]] = {}
        self.wallets: Dict[str, Dict[str, Any]] = {}
        self.credit_scores: Dict[str, Dict[str, Any]] = {}
        self.jobs: Dict[str, Dict[str, Any]] = {}
        self.transactions: List[Dict[str, Any]] = []
        
    def collection(self, name: str):
        """Mock collection"""
        return MockCollection(self, name)
    
    def get_collection_data(self, name: str) -> Dict[str, Dict[str, Any]]:
        """Get the actual data store for a collection"""
        if name == 'users':
            return self.users
        elif name == 'wallets':
            return self.wallets
        elif name == 'credit_scores' or name == 'creditScores':
            return self.credit_scores
        elif name == 'jobs':
            return self.jobs
        else:
            # Dynamic collections
            if not hasattr(self, f'_{name}'):
                setattr(self, f'_{name}', {})
            return getattr(self, f'_{name}')


class MockCollection:
    """Mock Firestore collection"""
    
    def __init__(self, db: MockDatabase, name: str):
        self.db = db
        self.name = name
        self.data = db.get_collection_data(name)
    
    def document(self, doc_id: str):
        """Get a document reference"""
        return MockDocument(self.data, doc_id)
    
    def where(self, field: str, op: str, value: Any):
        """Mock where query"""
        return MockQuery(self.data, field, op, value)
    
    def stream(self):
        """Stream all documents"""
        for doc_id, doc_data in self.data.items():
            yield MockDocumentSnapshot(doc_id, doc_data)
    
    def get(self):
        """Get all documents"""
        return [MockDocumentSnapshot(doc_id, doc_data) 
                for doc_id, doc_data in self.data.items()]


class MockDocument:
    """Mock Firestore document"""
    
    def __init__(self, collection_data: Dict, doc_id: str):
        self.collection_data = collection_data
        self.doc_id = doc_id
    
    def get(self):
        """Get document"""
        if self.doc_id in self.collection_data:
            return MockDocumentSnapshot(self.doc_id, self.collection_data[self.doc_id])
        return MockDocumentSnapshot(self.doc_id, None)
    
    def set(self, data: Dict[str, Any], merge: bool = False):
        """Set document data"""
        if merge and self.doc_id in self.collection_data:
            self.collection_data[self.doc_id].update(data)
        else:
            self.collection_data[self.doc_id] = data
    
    def update(self, data: Dict[str, Any]):
        """Update document"""
        if self.doc_id in self.collection_data:
            self.collection_data[self.doc_id].update(data)
        else:
            self.collection_data[self.doc_id] = data
    
    def delete(self):
        """Delete document"""
        if self.doc_id in self.collection_data:
            del self.collection_data[self.doc_id]


class MockQuery:
    """Mock Firestore query"""
    
    def __init__(self, data: Dict, field: str, op: str, value: Any):
        self.data = data
        self.field = field
        self.op = op
        self.value = value
    
    def stream(self):
        """Stream query results"""
        for doc_id, doc_data in self.data.items():
            if self._matches(doc_data):
                yield MockDocumentSnapshot(doc_id, doc_data)
    
    def get(self):
        """Get query results"""
        results = []
        for doc_id, doc_data in self.data.items():
            if self._matches(doc_data):
                results.append(MockDocumentSnapshot(doc_id, doc_data))
        return results
    
    def limit(self, count: int):
        """Limit results"""
        return self
    
    def _matches(self, doc_data: Dict) -> bool:
        """Check if document matches query"""
        if self.field not in doc_data:
            return False
        
        doc_value = doc_data[self.field]
        
        if self.op == '==':
            return doc_value == self.value
        elif self.op == '!=':
            return doc_value != self.value
        elif self.op == '>':
            return doc_value > self.value
        elif self.op == '>=':
            return doc_value >= self.value
        elif self.op == '<':
            return doc_value < self.value
        elif self.op == '<=':
            return doc_value <= self.value
        elif self.op == 'in':
            return doc_value in self.value
        elif self.op == 'array-contains':
            return self.value in doc_value if isinstance(doc_value, list) else False
        
        return False


class MockDocumentSnapshot:
    """Mock Firestore document snapshot"""
    
    def __init__(self, doc_id: str, data: Optional[Dict[str, Any]]):
        self.id = doc_id
        self._data = data
    
    def exists(self) -> bool:
        """Check if document exists"""
        return self._data is not None
    
    def to_dict(self) -> Optional[Dict[str, Any]]:
        """Get document data"""
        return self._data.copy() if self._data else None


# Global mock database instance
_mock_db = None


def get_mock_db() -> MockDatabase:
    """Get or create mock database instance"""
    global _mock_db
    if _mock_db is None:
        _mock_db = MockDatabase()
        print("📦 Using MOCK DATABASE (Firebase unavailable)")
    return _mock_db

